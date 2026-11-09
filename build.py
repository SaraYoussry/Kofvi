#!/usr/bin/env python3
"""Build planner/social/index.html (Social Media Planner) from app/src.html + app/assets.js.  Run: python3 build.py"""
from pathlib import Path
root = Path(__file__).parent
src = (root / "app/src.html").read_text(encoding="utf-8")
assets = (root / "app/assets.js").read_text(encoding="utf-8")
src = src.replace("<title>Mia Rose Content Studio</title>", "<title>Kofvi Content Planner</title>", 1)
head = ('<!doctype html>\n<html lang="en">\n<head>\n'
        '<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">\n')
src = src.replace('src="config.js"', 'src="/planner/config.js"')
body = src.replace("/*ASSETS*/", assets, 1).replace("</style>\n", "</style>\n</head>\n<body>\n", 1)
(root / "planner/social/index.html").write_text(head + body + "\n</body>\n</html>\n", encoding="utf-8")
print("built planner/social/index.html", round(len(body) / 1024), "KB")
