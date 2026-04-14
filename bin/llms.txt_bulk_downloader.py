#!/usr/bin/env python3
# Yeah IK scraping is annoying asf but these companies get what they deserve

from __future__ import annotations

import argparse
import concurrent.futures
import logging
import os
import re

import urllib
import urllib.parse
import urllib3.util

import concurrent.futures
from pathlib import Path
from typing import Iterable, Optional, Set

import requests
import requests.adapters
from tqdm import tqdm


MAX_PARALLEL_DOWNLOADS: int = 5
ALLOWED_EXTS: Set[str] = {
    e.lower()
    for e in (
        "md",
        "txt",
        "json",
        "json5",
        "yaml",
        "toml",
        "ron",
        "mdx",
    )
}
BUFSIZ: int = 8192
HTTP_HEADERS: dict[str, str] = {
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:149.0) Gecko/20100101 Firefox/149.0"
}
HTTP_TIMEOUT: int = 5
HTTP_NUM_RETRIES: int = 3

# Implementation constants

URL_FIELD_REGEX: re.Pattern = re.compile(
    r"^[^\[]*\[\s*([^\]]+)\s*\]\s*\(\s*([^\)]+)\)\s*:?\s*(.*)$"
)
URL_SLASHNORM_REGEX: re.Pattern = re.compile(r"/+")
URL_EXPECTED_LAYOUT: str = "scheme://netloc/path?query#fragment"


# TODO: Fix the following example:
# markdown URL: /docs/get-started/reinforcement-learning-rl-guide/vision-reinforcement-learning-vlm-rl.md
# llms


# TODO: Fix the following example:
# markdown URL: /docs/get-started/reinforcement-learning-rl-guide/vision-reinforcement-learning-vlm-rl.md
# llms.txt URL: https://unsloth.ai/docs/llms.txt
# Desired URL should be hostname-relative, so:
# Desired URL: https://unsloth.ai/docs/get-started/reinforcement-learning-rl-guide/vision-reinforcement-learning-vlm-rl.md
# The following sed command is a workaround:
# sed -i 's/\](\/docs/\](https:\/\/unsloth\.ai\/docs/' ./llms.txt
class NormalizedUrl:
    url_split: urllib.parse.SplitResult
    url: str
    path: Path
    relpath: str

    def __init__(
        self, url: urllib.parse.SplitResult, relpath: str, output_dir: Path
    ) -> None:
        self.url_split = url
        self.url = url.geturl()
        self.relpath = relpath
        self.path = output_dir / relpath

    @staticmethod
    def try_new(
        url: str,
        output_dir: Path,
        path_prefix: str = "",
        allow_any_extension: bool = False,
    ) -> Optional[NormalizedUrl]:
        parsed = urllib.parse.urlsplit(url)
        if not parsed.scheme:
            logging.error(f"Missing scheme: `{url}`, expected {URL_EXPECTED_LAYOUT}")
            return None
        if not parsed.netloc:
            logging.error(f"Missing netloc: `{url}`, expected {URL_EXPECTED_LAYOUT}")
            return None

        path = urllib.parse.unquote(parsed.path)
        path = URL_SLASHNORM_REGEX.sub(path, "/")

        if path.endswith("/"):
            newpath = path + "index.html"
            logging.debug(
                f"Replacing default http path query `{path}` with `{newpath}`"
            )
            path = newpath

        if not allow_any_extension:
            _prefix, _sep, suffix = path.rpartition(".")

            if suffix not in ALLOWED_EXTS:
                logging.warning(
                    f"URL `{url}` has invalid extension `{suffix}`, must be one of: {ALLOWED_EXTS}"
                )
                return None

        path = path.lstrip(path_prefix)
        path = path.lstrip("/")

        return NormalizedUrl(url=parsed, relpath=path, output_dir=output_dir)

    def __str__(self) -> str:
        return f"{self.url} => {self.path}"


class MarkdownUrlLine:
    text: str
    url: str
    description: Optional[str]

    def __init__(self, text: str, url: str, description: Optional[str]):
        self.text = text
        self.url = url
        self.description = description

    @staticmethod
    def try_parse(line: str) -> Optional[MarkdownUrlLine]:
        logging.debug(f"Parsing line `{line}`")

        fields = URL_FIELD_REGEX.match(line)
        if fields is None:
            logging.debug("Skipping, no regex matches")
            return None

        text = ""
        url = ""
        description = None

        try:
            text = fields.group(1)
        except Exception as ex:
            logging.debug(f"Skipping displaytext for line, received exception: {ex}")
            return None

        try:
            url = fields.group(2)
        except Exception as ex:
            logging.debug(f"Skipping url for line, received exception: {ex}")
            return None

        try:
            description = fields.group(3)
        except Exception as ex:
            logging.debug(f"Skipping description for line, received exception: {ex}")

        return MarkdownUrlLine(text=text, url=url, description=description)

    def __str__(self) -> str:
        fmt = f"- [{self.text}]({self.url})"

        if self.description is not None:
            fmt = f"{fmt}: {self.description}"

        return fmt


class DownloadTask:
    url: NormalizedUrl
    display: str

    def __init__(self, url: NormalizedUrl, source_url_text: str):
        self.url = url
        self.display = source_url_text

    @staticmethod
    def try_parse_new(
        output_dir: Path,
        markdown_line: str,
        force_redownload: bool,
        allow_any_extension: bool,
        path_prefix: str,
    ) -> Optional[DownloadTask]:
        line: Optional[MarkdownUrlLine] = MarkdownUrlLine.try_parse(markdown_line)
        if line is None:
            return None

        logging.debug(f"Got line: {line}")

        parsed: Optional[NormalizedUrl] = NormalizedUrl.try_new(
            url=line.url,
            output_dir=output_dir,
            path_prefix=path_prefix,
            allow_any_extension=allow_any_extension,
        )
        if parsed is None:
            return None

        if not force_redownload:
            if parsed.path.exists():
                logging.info(f"Path exists: {parsed}")
                return None

        logging.debug(f"Got url: {parsed}")

        return DownloadTask(url=parsed, source_url_text=line.text)

    def download_or_throw(self, session: requests.Session):
        logging.debug(f"Starting download: {self}")

        with session.get(
            url=self.url.url,
            headers=HTTP_HEADERS,
            allow_redirects=True,
            stream=True,
            timeout=HTTP_TIMEOUT,
        ) as resp:
            resp.raise_for_status()

            logging.debug(f"{resp.status_code}: `{resp.reason}` for url `{resp.url}`")

            self.url.path.parent.mkdir(parents=True, exist_ok=True)
            with self.url.path.open("wb") as fh:
                for chunk in resp.iter_content(chunk_size=BUFSIZ):
                    if chunk:
                        fh.write(chunk)

    def try_download(self, session: requests.Session) -> bool:
        try:
            self.download_or_throw(session=session)
            return True
        except Exception as ex:
            logging.error(f"{self}, exception: {ex}")
            return False

    def __str__(self) -> str:
        if len(self.display) == 0:
            return f"{self.display}: {self.url}"

        return str(self.url)


def parse_llmstxt(
    lines: Iterable[str],
    output_dir: Path,
    force_redownload: bool,
    allow_any_extension: bool,
    path_prefix: str,
) -> list[DownloadTask]:
    tasks: list[DownloadTask] = []

    for line in lines:
        task: Optional[DownloadTask] = DownloadTask.try_parse_new(
            output_dir=output_dir,
            markdown_line=line,
            force_redownload=force_redownload,
            allow_any_extension=allow_any_extension,
            path_prefix=path_prefix,
        )

        if task is not None:
            tasks.append(task)

    return tasks


def get_llmstxt(
    session: requests.Session,
    url: str,
    output_dir: Path,
    force_redownload: bool,
    is_second_try: bool = True,
) -> tuple[NormalizedUrl, list[str]]:
    logging.debug(f"url: `{url}`")

    parsed: Optional[NormalizedUrl] = NormalizedUrl.try_new(
        url=url, output_dir=output_dir, path_prefix="", allow_any_extension=True
    )
    if parsed is None:
        raise requests.utils.InvalidURL(f"Failed to parse lms.txt url: `{url}`")

    # HACK: Workaround for modified llms.txt from https://unsloth.ai/docs/llms.txt
    if not is_second_try and not force_redownload:
        llmstxt_local = Path.cwd() / "llms.txt"
        if llmstxt_local.exists():
            logging.info(f"Override: Found local llmstxt: {llmstxt_local}")
            try:
                with llmstxt_local.open(mode="r", buffering=BUFSIZ) as fh:
                    return parsed, fh.readlines()
            except Exception as ex:
                logging.warning(f"Failed to read llmstxt_local: {ex}")

    logging.debug(f"llms.txt: {parsed}")

    if parsed.path.exists():
        logging.info(f"Found llms.txt: {parsed}")

        if force_redownload and not is_second_try:
            logging.debug("Forcing redownload")
        else:
            with parsed.path.open(mode="r", buffering=BUFSIZ) as fh:
                return parsed, fh.readlines()

    elif is_second_try:
        raise FileNotFoundError(f"Failed to download: {parsed}")

    task = DownloadTask(parsed, source_url_text="llms.txt")
    task.download_or_throw(session)

    return get_llmstxt(
        session=session,
        url=url,
        output_dir=output_dir,
        force_redownload=False,
        is_second_try=False,
    )

    # raise NotImplementedError("Still have to write download logic")


def make_session() -> requests.Session:
    session = requests.Session()
    retries = urllib3.util.Retry(
        total=HTTP_NUM_RETRIES,
        backoff_factor=0.75,
        backoff_jitter=0.25,
        redirect=10,
    )
    adapter = requests.adapters.HTTPAdapter(
        max_retries=retries, pool_maxsize=MAX_PARALLEL_DOWNLOADS
    )

    for ty in ["https", "http", "ftp", "nfs", "smb", "file", "ssh", "ldap"]:
        session.mount(prefix=f"{ty}://", adapter=adapter)

    return session


def task_parallel_download(tasks: list[DownloadTask]):
    failures = []
    with concurrent.futures.ThreadPoolExecutor(
        max_workers=MAX_PARALLEL_DOWNLOADS
    ) as executor:
        futures = [executor.submit(task.try_download, session) for task in tasks]

        for future in tqdm(
            concurrent.futures.as_completed(futures),
            total=len(futures),
            desc="Downloading files",
        ):
            task = future.result()
            if not task:
                failures.append(task)
                pass

    logging.info(f"Downloaded {len(tasks) - len(failures)} files.")


if __name__ == "__main__":
    loglevel: Optional[str] = os.getenv(key="LOG_LEVEL")
    if loglevel is not None:
        logging.basicConfig(level=loglevel)
    else:
        logging.basicConfig()

    parser = argparse.ArgumentParser(
        prog="llms_bulk_downloader",
        description="Download all assets referenced in an llms.txt file.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        add_help=True,
        allow_abbrev=True,
        suggest_on_error=True,
    )
    parser.add_argument(
        "-o",
        "--output",
        dest="output_dir",
        type=Path,
        default=Path.cwd(),
        help="Directory where all files will be written",
    )
    parser.add_argument(
        "-f",
        "--force",
        dest="force",
        action="store_true",
        default=False,
        help="Redownload files even if they already exist on disk",
    )
    parser.add_argument(
        "-a",
        "--all",
        dest="allow_all",
        action="store_true",
        default=False,
        help=f"Allow any file extension to be downloaded. Default allowed extensions are: {ALLOWED_EXTS}",
    )
    parser.add_argument(
        "url",
        type=str,
        help="URL of the llms.txt file (must end with '/llms.txt').",
    )

    args = parser.parse_args()

    output_dir = args.output_dir
    force_redownload = args.force
    allow_all = args.allow_all
    llmstxt = args.url

    session = make_session()

    # logging.debug(f"Output dir: {output_dir}")
    llmstxt_url, llmstxt = get_llmstxt(
        session=session,
        url=llmstxt,
        output_dir=output_dir,
        force_redownload=force_redownload,
        is_second_try=False,
    )

    prefixed = Path(llmstxt_url.relpath).parent
    prefixed_str = str(prefixed)

    tasks = parse_llmstxt(
        lines=llmstxt,
        output_dir=output_dir,
        force_redownload=force_redownload,
        allow_any_extension=allow_all,
        path_prefix=prefixed_str,
    )

    task_parallel_download(tasks=tasks)
