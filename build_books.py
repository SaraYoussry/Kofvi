#!/usr/bin/env python3
"""Build planner/books/index.html (Book Tracker) from app/books/src.html + assets.js + sample.js.  Run: python3 build_books.py"""
from pathlib import Path
root = Path(__file__).parent
d = root / "app/books"
src = (d / "src.html").read_text(encoding="utf-8")
assets = (d / "assets.js").read_text(encoding="utf-8").rstrip().rstrip(";")
assets = assets[:-1] + ',"catW":0.54,"vaseW":0.68,"stackW":0.89,"ivyW":0.66};'
sample = (d / "sample.js").read_text(encoding="utf-8")
body = src.replace("/*ASSETS*/", assets, 1).replace("/*SAMPLE*/", sample, 1)
body = body.replace("</style>\n", "</style>\n</head>\n<body>\n", 1)
out = root / "planner/books/index.html"
out.write_text('<!doctype html>\n<html lang="en">\n<head>\n' + body + "\n</body>\n</html>\n", encoding="utf-8")
print("built", out.relative_to(root), round(len(body) / 1024), "KB")
