#!/usr/bin/env python3
"""Build planner/adhd/ (ADHD Life Planner web app) from app/adhd/app.html.
app.html is the built planner from Claude's v4 sources (the same file as the claude.ai preview).
This script adds the Kofvi account layer: config + Supabase, the install manifest and the offline service worker.
Run from the repo root: python3 app/adhd/build_adhd.py"""
from pathlib import Path
root = Path(__file__).resolve().parents[1].parent
src = (root / "app/adhd/app.html").read_text(encoding="utf-8")
out_dir = root / "planner/adhd"
head = ('<link rel="manifest" href="manifest.webmanifest">\n<meta name="theme-color" content="#3E95E0">\n'
        '<link rel="apple-touch-icon" href="icon-180.png">\n<link rel="icon" type="image/png" href="icon-192.png">\n'
        '<meta name="apple-mobile-web-app-capable" content="yes">\n<meta name="mobile-web-app-capable" content="yes">\n'
        '<meta name="apple-mobile-web-app-status-bar-style" content="default">\n<meta name="apple-mobile-web-app-title" content="Kofvi Planner">\n')
libs = ('<script src="/planner/config.js"></script>\n'
        '<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/dist/umd/supabase.js"></script>\n')
assert src.startswith('<meta charset="utf-8">')
body = src.replace('<title>ADHD Life Planner App</title>', '<title>ADHD Life Planner · Kofvi</title>\n' + head, 1)
i = body.index('<script>\n(functio')
body = body[:i] + libs + body[i:]
(out_dir / "index.html").write_text('<!doctype html>\n<html lang="en">\n<head>\n' + body + "\n</html>\n", encoding="utf-8")
print("built planner/adhd/index.html", round(len(body) / 1024), "KB")
