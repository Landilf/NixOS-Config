#!/usr/bin/env python3

import calendar
import json
from datetime import datetime

try:
    from zoneinfo import ZoneInfo  # py3.9+
except Exception:  # pragma: no cover
    ZoneInfo = None


TZ = "Europe/Moscow"

# Filled circle with "cut-out" digit (renders as background color).
NEG_CIRCLED = {
    "0": "⓿",
    "1": "❶",
    "2": "❷",
    "3": "❸",
    "4": "❹",
    "5": "❺",
    "6": "❻",
    "7": "❼",
    "8": "❽",
    "9": "❾",
}


def now_in_tz() -> datetime:
    if ZoneInfo is None:
        return datetime.now()
    try:
        return datetime.now(ZoneInfo(TZ))
    except Exception:
        return datetime.now()


def neg_circled_number(n: int) -> str:
    s = str(n)
    if n == 10:
        return "❿"
    if 11 <= n <= 20:
        return chr(0x24EB + (n - 11))  # ⓫..⓴
    return "".join(NEG_CIRCLED.get(ch, ch) for ch in s)


def month_block(year: int, month: int, today: datetime) -> list[str]:
    cal = calendar.Calendar(firstweekday=0)  # Monday
    month_name = calendar.month_name[month]

    width = 20
    header = month_name.center(width)
    weekdays = "Mo Tu We Th Fr Sa Su"

    lines = [header, weekdays]
    for week in cal.monthdayscalendar(year, month):
        cells: list[str] = []
        for day in week:
            if day == 0:
                cells.append("  ")
            elif year == today.year and month == today.month and day == today.day:
                mark = neg_circled_number(day)
                cells.append(mark.rjust(2))
            else:
                cells.append(str(day).rjust(2))
        lines.append(" ".join(cells))

    while len(lines) < 8:
        lines.append(" " * width)
    return lines[:8]


def year_calendar(year: int, today: datetime) -> str:
    blocks = [month_block(year, m, today) for m in range(1, 13)]
    rows: list[str] = []
    gap = "  "
    for i in range(0, 12, 3):
        for line_idx in range(8):
            rows.append(gap.join(blocks[i + j][line_idx] for j in range(3)).rstrip())
        rows.append("")
    return "\n".join(rows).rstrip()


def main() -> None:
    now = now_in_tz()
    tooltip = f"<big>{now.year}</big>\n<tt><small>{year_calendar(now.year, now)}</small></tt>"
    text = now.strftime(" %H:%M")
    print(json.dumps({"text": text, "tooltip": tooltip}))


if __name__ == "__main__":
    main()

