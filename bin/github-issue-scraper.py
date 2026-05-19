#!/usr/bin/env python3
"""
Fetch all issues + comments via GitHub GraphQL in batches.
Requires: pip install pydantic requests
"""

import os
import sys
import time
import json
from pathlib import Path
from typing import List, Optional, Any, Dict
import requests
import subprocess
from pydantic import BaseModel, Field
import re

print("SCRAPE THAT SHIT BOIIIIII")


def get_github_token() -> Optional[str]:
    env = os.getenv("GITHUB_TOKEN")
    if env:
        return env
    # Look for GH hosts.yml in config dir
    cfg = Path(os.getenv("XDG_CONFIG_HOME", str(Path.home() / ".config")))
    cfg = cfg / "gh" / "hosts.yml"

    txt = cfg.read_text(encoding="utf-8")

    # match first occurrence of "oauth_token: <token>" at line start (allow leading spaces)
    m = re.search(r"(?m)^\s*oauth_token:\s*(\S+)", txt)
    if m:
        return m.group(1)
    return None


GITHUB_TOKEN = get_github_token()
if not GITHUB_TOKEN:
    print("Set GITHUB_TOKEN env var", file=sys.stderr)
    sys.exit(1)


def cli(command: list[str]) -> str:
    return (
        subprocess.run(command, check=True, stdout=subprocess.PIPE)
        .stdout.decode()
        .strip()
    )


OWNER_REPO = os.getenv("REPO")  # e.g. "owner/repo". If not set, will try gh to detect.
if not OWNER_REPO:
    try:
        OWNER_REPO = cli(
            [
                "gh",
                "repo",
                "view",
                "--json",
                "nameWithOwner",
                "-q",
                ".nameWithOwner",
            ],
        )
    except Exception as e:
        print(
            "Provide REPO env var (owner/repo) or have gh CLI available",
            file=sys.stderr,
        )
        raise

API_URL = "https://api.github.com/graphql"
HEADERS = {"Authorization": f"bearer {GITHUB_TOKEN}"}

OUT = "issues_with_comments.ndjson"
BATCH_ISSUES = 50  # issues per GraphQL query
COMMENTS_PER_ISSUE = 100  # comments per issue page


class Actor(BaseModel):
    login: Optional[str]
    url: Optional[str]


class Comment(BaseModel):
    id: str
    body: Optional[str]
    createdAt: Optional[str]
    updatedAt: Optional[str]
    author: Optional[Actor]
    url: Optional[str]


class Issue(BaseModel):
    id: str
    number: int
    title: Optional[str]
    body: Optional[str]
    createdAt: Optional[str]
    updatedAt: Optional[str]
    closedAt: Optional[str]
    url: Optional[str]
    author: Optional[Actor]
    comments: List[Comment] = Field(default_factory=list)
    labels: Optional[Any]
    state: Optional[str]


def gql(query: str, variables: Dict[str, Any]) -> Dict[str, Any]:
    resp = requests.post(
        API_URL, json={"query": query, "variables": variables}, headers=HEADERS
    )
    if resp.status_code == 200:
        j = resp.json()
        if "errors" in j:
            raise RuntimeError(f"GQL errors: {j['errors']}")
        return j["data"]
    elif resp.status_code == 502:
        time.sleep(1)
        return gql(query, variables)
    else:
        raise RuntimeError(f"Query failed: {resp.status_code} {resp.text}")


# GraphQL query: fetch a page of issues (by cursor), for each issue fetch comments (first COMMENTS_PER_ISSUE).
# We'll also fetch comments' pageInfo to support comment pagination if needed (not implemented deep paging here).
QUERY = """
query ($owner: String!, $name: String!, $issues_first: Int!, $issues_after: String, $comments_first: Int!) {
  repository(owner: $owner, name: $name) {
    issues(first: $issues_first, after: $issues_after, orderBy: {field: CREATED_AT, direction: ASC}, states: [OPEN, CLOSED]) {
      pageInfo { hasNextPage endCursor }
      nodes {
        id number title body createdAt updatedAt closedAt url state
        author { login url }
        labels(first:10) { nodes { name } }
        comments(first: $comments_first) {
          totalCount
          pageInfo { hasNextPage endCursor }
          nodes {
            id body createdAt updatedAt url
            author { login url }
          }
        }
      }
    }
  }
}
"""

owner, name = OWNER_REPO.split("/", 1)
issues_after = None
written = 0

with open(OUT, "w", encoding="utf-8") as out_f:
    while True:
        vars = {
            "owner": owner,
            "name": name,
            "issues_first": BATCH_ISSUES,
            "issues_after": issues_after,
            "comments_first": COMMENTS_PER_ISSUE,
        }
        data = gql(QUERY, vars)
        repo = data.get("repository")
        if not repo:
            print("Repo not found in GraphQL response", file=sys.stderr)
            break
        issues = repo["issues"]["nodes"] or []
        if not issues:
            break
        for node in issues:
            # Convert comments.nodes -> list of Comment models
            comments_nodes = node.get("comments", {}).get("nodes", []) or []
            comments = []
            for c in comments_nodes:
                comments.append(Comment(**c).dict())
            issue_obj = Issue(
                id=node.get("id"),
                number=node.get("number"),
                title=node.get("title"),
                body=node.get("body"),
                createdAt=node.get("createdAt"),
                updatedAt=node.get("updatedAt"),
                closedAt=node.get("closedAt"),
                url=node.get("url"),
                author=node.get("author"),
                comments=comments,
                labels=node.get("labels"),
                state=node.get("state"),
            )
            out_f.write(json.dumps(issue_obj.dict(), ensure_ascii=False) + "\n")
            written += 1
            if written % 50 == 0:
                print(f"Wrote {written} issues...", file=sys.stderr)
                if written % 200 == 0:
                    os.system("PAGER= gh api rate_limit --jq '.[].graphql'")
        page_info = repo["issues"]["pageInfo"]
        if page_info["hasNextPage"]:
            issues_after = page_info["endCursor"]
            # Rate-limit-friendly pause:
            time.sleep(0.2)
        else:
            break

print(f"Done. Wrote {written} items to {OUT}", file=sys.stderr)
