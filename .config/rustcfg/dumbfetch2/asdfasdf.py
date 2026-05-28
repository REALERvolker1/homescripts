#!/usr/bin/env python3

from __future__ import annotations
from typing import Any, Iterable, Self
from dataclasses import dataclass
import requests
import bs4
import sys
import pprint
@dataclass
class InputData:
	x: int
	character: str
	y: int

	@classmethod
	def specialized_listing(cls, table_rows: Iterable[bs4.Tag]) -> list[Self]:
		res = []
		for row in table_rows:
			rowdata = [cell.get_text(strip=True) for cell in row.find_all(["td", "th"])]
			if len(rowdata) >= 3:
				res.append(cls(x=int(rowdata[0]), character=rowdata[1], y=int(rowdata[2])))
		return res

def is_table_parsable(header_row: bs4.Tag) -> bool:
	table_headers = [cell.get_text(strip=True) for cell in header_row.find_all(["td", "th"])]
	if len(table_headers) == 3:
		# Fixed: was checking index 1 twice. Should be [2] for y-coordinate
		if (table_headers[0] == "x-coordinate" and
			table_headers[1] == "Character" and
			table_headers[2] == "y-coordinate"):
			return True
	return False

def main(url: str, session: requests.Session) -> int:


	res = session.get(url, timeout=15)  # <--- Critical: aborts after 15s instead of hanging forever
	res.raise_for_status()

	page = bs4.BeautifulSoup(res.text, "html.parser")
	table = page.find("table")
	if table is None:
		print(f"Error: No table found in '{url}'")
		return 2

	header_row = table.find("tr")
	if header_row is None or not is_table_parsable(header_row):
		print("Not a parsable table! Received headers:")
		pprint.pprint([cell.get_text(strip=True) for cell in header_row.find_all(["td", "th"])])
		return 2

	tbody = table.find("tbody")
	data_rows = tbody.find_all("tr")[1:] if tbody else table.find_all("tr")[1:]
	table_data = InputData.specialized_listing(data_rows)

	if not table_data:
		print("No data rows found.")
		return 0

	max_x = max(d.x for d in table_data)
	max_y = max(d.y for d in table_data)
	width, height = max_x + 1, max_y + 1

	buf: list[list[str]] = [[" " for _ in range(width)] for _ in range(height)]

	for d in table_data:
		buf[d.y][d.x] = d.character

	for line in buf:
		print("".join(line))

	return 0

if __name__ == "__main__":
	if len(sys.argv) < 2:
		print(f"Usage: {sys.argv[0]} [URL]")
		exit(1)

	session = requests.Session()
	session.headers.update({
		"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
	})
	main(sys.argv[1], session)
