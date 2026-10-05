#!/usr/bin/env python3
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlparse


class MetaParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.og_images: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag.lower() != "meta":
            return
        values = {key.lower(): value for key, value in attrs if value is not None}
        if values.get("property", "").lower() != "og:image":
            return
        content = values.get("content", "")
        self.og_images.append(content)


def main() -> int:
    root = Path("site")
    failures: list[str] = []
    checked = 0

    for path in sorted(root.rglob("*.html")):
        parser = MetaParser()
        parser.feed(path.read_text(encoding="utf-8"))
        if not parser.og_images:
            continue
        checked += 1
        if len(parser.og_images) != 1:
            failures.append(f"{path}: expected exactly one og:image, found {len(parser.og_images)}")
            continue

        value = parser.og_images[0]
        parsed = urlparse(value)
        if parsed.scheme != "https" or parsed.netloc != "espanaoutdoor.es":
            failures.append(f"{path}: og:image must use the first-party HTTPS host: {value}")
        if parsed.query or parsed.fragment:
            failures.append(f"{path}: og:image must not contain query/fragment parameters: {value}")

    if failures:
        print("\n".join(failures))
        return 1

    print(f"OG image policy OK: {checked} HTML page(s) with a canonical og:image")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
