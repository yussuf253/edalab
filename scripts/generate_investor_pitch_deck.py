from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Sequence

from PIL import Image
from reportlab.lib.colors import Color, HexColor, white
from reportlab.lib.units import inch
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfgen import canvas


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_PDF = ROOT / "docs" / "EdaLab_Investor_Pitch_Deck_2026_v2.pdf"
BUILD_DIR = ROOT / "build" / "pitch_deck_assets"
BUILD_DIR.mkdir(parents=True, exist_ok=True)

PAGE_W = 13.333 * inch
PAGE_H = 7.5 * inch
SAFE_X = 42
SAFE_BOTTOM = 34
HEADER_H = 132
CONTENT_GAP = 14

PALETTE = {
    "midnight": HexColor("#051726"),
    "navy": HexColor("#0C2740"),
    "indigo": HexColor("#283593"),
    "teal": HexColor("#0EA5A0"),
    "mint": HexColor("#10B981"),
    "sky": HexColor("#0284C7"),
    "amber": HexColor("#F59E0B"),
    "rose": HexColor("#E11D48"),
    "ink": HexColor("#0F172A"),
    "slate": HexColor("#334155"),
    "muted": HexColor("#64748B"),
    "paper": HexColor("#F8FAFC"),
    "soft": HexColor("#E2E8F0"),
}


@dataclass
class SlideCtx:
    c: canvas.Canvas
    page: int
    total: int


@dataclass
class Box:
    x: float
    y: float
    w: float
    h: float


def lerp(a: Color, b: Color, t: float) -> Color:
    return Color(
        a.red + (b.red - a.red) * t,
        a.green + (b.green - a.green) * t,
        a.blue + (b.blue - a.blue) * t,
    )


def gradient_bg(c: canvas.Canvas, top: Color, bottom: Color) -> None:
    steps = 140
    h = PAGE_H / steps
    for i in range(steps):
        t = i / max(steps - 1, 1)
        c.setFillColor(lerp(top, bottom, t))
        c.rect(0, PAGE_H - (i + 1) * h, PAGE_W, h + 1, stroke=0, fill=1)


def fit_line(text: str, font: str, size: float, width: float) -> list[str]:
    words = text.split()
    if not words:
        return []
    lines: list[str] = []
    line = words[0]
    for w in words[1:]:
        trial = f"{line} {w}"
        if pdfmetrics.stringWidth(trial, font, size) <= width:
            line = trial
        else:
            lines.append(line)
            line = w
    lines.append(line)
    return lines


def text_block(
    c: canvas.Canvas,
    text: str,
    box: Box,
    *,
    font: str = "Helvetica",
    size: float = 12,
    color: Color = PALETTE["ink"],
    leading: float | None = None,
    max_lines: int | None = None,
) -> float:
    lines = fit_line(text, font, size, box.w)
    if max_lines is not None and len(lines) > max_lines:
        lines = lines[:max_lines]
        if lines:
            line = lines[-1]
            while line and pdfmetrics.stringWidth(line + "…", font, size) > box.w:
                line = line[:-1]
            lines[-1] = (line + "…") if line else "…"
    if leading is None:
        leading = size * 1.3
    y = box.y + box.h
    c.setFillColor(color)
    c.setFont(font, size)
    for line in lines:
        if y - leading < box.y:
            break
        c.drawString(box.x, y - leading, line)
        y -= leading
    return y


def bullet_height(items: Sequence[str], width: float, size: float) -> float:
    leading = size * 1.28
    h = 0.0
    for item in items:
        lines = fit_line(item, "Helvetica", size, width - 18)
        count = max(1, len(lines))
        h += count * leading + size * 0.45
    return h


def bullets_fit(
    c: canvas.Canvas,
    items: Sequence[str],
    box: Box,
    *,
    max_size: float = 14,
    min_size: float = 10.5,
    bullet_color: Color = PALETTE["teal"],
    text_color: Color = PALETTE["ink"],
) -> float:
    size = max_size
    while size >= min_size:
        if bullet_height(items, box.w, size) <= box.h:
            break
        size -= 0.5

    y = box.y + box.h
    leading = size * 1.28
    c.setFont("Helvetica", size)

    for item in items:
        lines = fit_line(item, "Helvetica", size, box.w - 18)
        if not lines:
            continue
        needed = len(lines) * leading + size * 0.45
        if y - needed < box.y:
            break

        c.setFillColor(bullet_color)
        c.circle(box.x + 4, y - size * 0.55, 2.6, stroke=0, fill=1)
        c.setFillColor(text_color)
        c.drawString(box.x + 13, y - size, lines[0])
        yy = y - leading
        for line in lines[1:]:
            c.drawString(box.x + 13, yy - size, line)
            yy -= leading
        y = yy - size * 0.45
    return size


def header(
    ctx: SlideCtx,
    title: str,
    subtitle: str,
    *,
    bg_top: Color,
    bg_bottom: Color,
    accent: Color,
    dark: bool = True,
    tag: str | None = None,
) -> Box:
    c = ctx.c
    gradient_bg(c, bg_top, bg_bottom)

    # Soft decorative shapes
    c.setFillColor(Color(1, 1, 1, alpha=0.06) if dark else Color(1, 1, 1, alpha=0.35))
    c.circle(PAGE_W - 52, PAGE_H - 18, 76, stroke=0, fill=1)
    c.circle(PAGE_W - 134, PAGE_H - 42, 48, stroke=0, fill=1)

    text_main = white if dark else PALETTE["ink"]
    text_sub = Color(1, 1, 1, alpha=0.9) if dark else PALETTE["slate"]

    if tag:
        c.setFillColor(Color(1, 1, 1, alpha=0.16) if dark else HexColor("#DBEAFE"))
        c.roundRect(SAFE_X, PAGE_H - 34, 300, 20, 8, stroke=0, fill=1)
        c.setFillColor(text_main if dark else PALETTE["sky"])
        c.setFont("Helvetica-Bold", 9)
        c.drawString(SAFE_X + 10, PAGE_H - 27, tag.upper())

    c.setFillColor(text_main)
    c.setFont("Helvetica-Bold", 30)
    c.drawString(SAFE_X, PAGE_H - 70, title)
    c.setFillColor(text_sub)
    c.setFont("Helvetica", 13)
    c.drawString(SAFE_X, PAGE_H - 92, subtitle)

    c.setFillColor(accent)
    c.rect(SAFE_X, PAGE_H - 102, 220, 4, stroke=0, fill=1)

    # Footer
    c.setFillColor(Color(1, 1, 1, alpha=0.10) if dark else Color(0, 0, 0, alpha=0.05))
    c.rect(0, 0, PAGE_W, 22, stroke=0, fill=1)
    c.setFillColor(Color(1, 1, 1, alpha=0.82) if dark else PALETTE["muted"])
    c.setFont("Helvetica", 9)
    c.drawString(16, 7, "EdaLab | Confidential Investor Deck | April 2026")
    c.drawRightString(PAGE_W - 16, 7, f"{ctx.page}/{ctx.total}")

    return Box(SAFE_X, SAFE_BOTTOM, PAGE_W - SAFE_X * 2, PAGE_H - HEADER_H - SAFE_BOTTOM - CONTENT_GAP)


def card(c: canvas.Canvas, box: Box, fill: Color = white, radius: float = 12, stroke: Color | None = None) -> None:
    c.setFillColor(fill)
    if stroke:
        c.setStrokeColor(stroke)
        c.setLineWidth(0.8)
        c.roundRect(box.x, box.y, box.w, box.h, radius, stroke=1, fill=1)
    else:
        c.roundRect(box.x, box.y, box.w, box.h, radius, stroke=0, fill=1)


def crop_to_ratio(src: Path, dst: Path, ratio: float) -> None:
    with Image.open(src) as img:
        img = img.convert("RGB")
        w, h = img.size
        cur = w / h
        if cur > ratio:
            nw = int(h * ratio)
            x = (w - nw) // 2
            img = img.crop((x, 0, x + nw, h))
        else:
            nh = int(w / ratio)
            y = (h - nh) // 2
            img = img.crop((0, y, w, y + nh))
        img.save(dst, "PNG")


def draw_image_cover(c: canvas.Canvas, src: Path, box: Box) -> None:
    tmp = BUILD_DIR / f"crop_{src.stem}_{int(box.w)}x{int(box.h)}.png"
    crop_to_ratio(src, tmp, box.w / box.h)
    c.drawImage(str(tmp), box.x, box.y, width=box.w, height=box.h, preserveAspectRatio=False, mask="auto")


def slide_01_cover(ctx: SlideCtx) -> None:
    c = ctx.c
    gradient_bg(c, PALETTE["midnight"], PALETTE["navy"])

    c.setFillColor(Color(1, 1, 1, alpha=0.08))
    c.circle(PAGE_W - 70, PAGE_H - 18, 84, stroke=0, fill=1)
    c.circle(PAGE_W - 160, PAGE_H - 92, 56, stroke=0, fill=1)

    c.setFillColor(white)
    c.setFont("Helvetica-Bold", 46)
    c.drawString(54, PAGE_H - 96, "EdaLab")
    c.setFont("Helvetica-Bold", 26)
    c.drawString(54, PAGE_H - 130, "The Multi-Vertical Services OS for African Cities")

    c.setFont("Helvetica", 14)
    c.drawString(54, PAGE_H - 154, "Investor Pitch Deck | Built for VCs and Angel Networks in Africa")

    banner = ROOT / "assets/images/banners/banner.png"
    if banner.exists():
        box = Box(54, 120, 520, 240)
        c.setFillColor(Color(1, 1, 1, alpha=0.12))
        c.roundRect(box.x - 3, box.y - 3, box.w + 6, box.h + 6, 14, stroke=0, fill=1)
        draw_image_cover(c, banner, box)

    shot = ROOT / "flutter_01.png"
    phone_frame = Box(PAGE_W - 290, 68, 208, 468)
    c.setFillColor(Color(1, 1, 1, alpha=0.12))
    c.roundRect(phone_frame.x - 10, phone_frame.y - 10, phone_frame.w + 20, phone_frame.h + 20, 30, stroke=0, fill=1)
    c.setFillColor(white)
    c.roundRect(phone_frame.x, phone_frame.y, phone_frame.w, phone_frame.h, 24, stroke=0, fill=1)
    if shot.exists():
        draw_image_cover(c, shot, Box(phone_frame.x + 9, phone_frame.y + 9, phone_frame.w - 18, phone_frame.h - 18))

    c.setFillColor(Color(1, 1, 1, alpha=0.18))
    c.roundRect(54, 56, 560, 46, 10, stroke=0, fill=1)
    c.setFillColor(white)
    c.setFont("Helvetica", 12)
    c.drawString(68, 73, "From discovery to dispatch across home services, health, mobility, food, and local commerce.")

    c.setFillColor(Color(1, 1, 1, alpha=0.10))
    c.rect(0, 0, PAGE_W, 22, stroke=0, fill=1)
    c.setFillColor(Color(1, 1, 1, alpha=0.82))
    c.setFont("Helvetica", 9)
    c.drawString(16, 7, "EdaLab | Confidential Investor Deck | April 2026")
    c.drawRightString(PAGE_W - 16, 7, f"{ctx.page}/{ctx.total}")


def slide_02_narrative(ctx: SlideCtx) -> None:
    c = ctx.c
    area = header(
        ctx,
        "Investor Narrative Architecture",
        "Built on structures used in high-conviction startup decks.",
        bg_top=HexColor("#0F172A"),
        bg_bottom=HexColor("#1E293B"),
        accent=PALETTE["teal"],
        dark=True,
        tag="design principle",
    )

    left = Box(area.x, area.y, area.w * 0.58, area.h)
    right = Box(area.x + area.w * 0.60, area.y, area.w * 0.40, area.h)

    card(c, left, fill=white)
    c.setFillColor(PALETTE["ink"])
    c.setFont("Helvetica-Bold", 21)
    c.drawString(left.x + 18, left.y + left.h - 30, "Slide flow used in this deck")

    flow = [
        "Problem -> Why now -> Product -> Moat -> Ask (Airbnb-style clarity)",
        "Company purpose + problem + solution + market + business model + team + vision (Sequoia framework)",
        "Legible, simple, obvious slides with one core takeaway per slide (YC guidance)",
        "12-14 slide format optimized for fast VC review behavior",
    ]
    bullets_fit(c, flow, Box(left.x + 18, left.y + 20, left.w - 36, left.h - 70), max_size=13.5)

    card(c, right, fill=HexColor("#ECFEFF"))
    c.setFillColor(PALETTE["sky"])
    c.setFont("Helvetica-Bold", 19)
    c.drawString(right.x + 18, right.y + right.h - 34, "What changed vs v1")

    bullets_fit(
        c,
        [
            "Hard safe-area system prevents any card/title overlap.",
            "Auto-fit text engine scales bullet size by available space.",
            "Stronger visual rhythm and section hierarchy.",
            "Data-led market slide with source-timestamped references.",
        ],
        Box(right.x + 18, right.y + 20, right.w - 36, right.h - 70),
        max_size=12.5,
    )


def slide_03_problem(ctx: SlideCtx) -> None:
    c = ctx.c
    area = header(
        ctx,
        "The Problem",
        "Urban African consumers and providers still operate in fragmented service stacks.",
        bg_top=HexColor("#F8FAFC"),
        bg_bottom=HexColor("#E2E8F0"),
        accent=PALETTE["rose"],
        dark=False,
        tag="market pain",
    )

    col_w = (area.w - 16) / 2
    a = Box(area.x, area.y, col_w, area.h)
    b = Box(area.x + col_w + 16, area.y, col_w, area.h)

    card(c, a, fill=white)
    card(c, b, fill=white)

    c.setFillColor(PALETTE["ink"])
    c.setFont("Helvetica-Bold", 20)
    c.drawString(a.x + 18, a.y + a.h - 30, "Consumer pain")
    bullets_fit(
        c,
        [
            "Too many disconnected apps and channels for essential daily services.",
            "Low trust in quality, pricing, and on-time fulfillment.",
            "Weak visibility on status and ETA creates booking anxiety.",
            "High switching friction lowers repeat behavior.",
        ],
        Box(a.x + 18, a.y + 18, a.w - 36, a.h - 60),
    )

    c.setFillColor(PALETTE["ink"])
    c.setFont("Helvetica-Bold", 20)
    c.drawString(b.x + 18, b.y + b.h - 30, "Provider pain")
    bullets_fit(
        c,
        [
            "Demand discovery is inconsistent and often offline.",
            "Workflows from quote to completion are operationally messy.",
            "No unified queue to move orders from pending to done.",
            "Idle time and failed dispatches reduce provider earnings.",
        ],
        Box(b.x + 18, b.y + 18, b.w - 36, b.h - 60),
    )


def slide_04_why_now(ctx: SlideCtx) -> None:
    c = ctx.c
    area = header(
        ctx,
        "Why Now: Africa is at an Inflection Point",
        "Connectivity, payments and policy are converging for platform-scale outcomes.",
        bg_top=HexColor("#ECFEFF"),
        bg_bottom=HexColor("#CCFBF1"),
        accent=PALETTE["teal"],
        dark=False,
        tag="timing",
    )

    gap = 12
    w = (area.w - gap) / 2
    h = (area.h - gap) / 2
    boxes = [
        Box(area.x, area.y + h + gap, w, h),
        Box(area.x + w + gap, area.y + h + gap, w, h),
        Box(area.x, area.y, w, h),
        Box(area.x + w + gap, area.y, w, h),
    ]

    facts = [
        (
            "416M users",
            "Mobile internet users across Africa (28% penetration) in 2024.",
            "GSMA Mobile Economy Africa 2025",
            PALETTE["sky"],
        ),
        (
            "$220B",
            "Mobile technologies' GDP contribution in Africa in 2024.",
            "GSMA Mobile Economy Africa 2025",
            PALETTE["teal"],
        ),
        (
            "$2T + 2.3B",
            "Mobile money annual transaction value and registered accounts in 2025.",
            "GSMA Mobile Money SOI 2026 (Mar 24, 2026)",
            PALETTE["mint"],
        ),
        (
            "1.3B / $3.4T",
            "AfCFTA connected market across 55 countries and combined GDP.",
            "World Bank AfCFTA overview",
            PALETTE["amber"],
        ),
    ]

    for box, (value, desc, src, accent) in zip(boxes, facts):
        card(c, box, fill=white)
        c.setFillColor(accent)
        c.rect(box.x, box.y + box.h - 7, box.w, 7, stroke=0, fill=1)
        c.setFillColor(PALETTE["ink"])
        c.setFont("Helvetica-Bold", 24)
        c.drawString(box.x + 14, box.y + box.h - 37, value)
        text_block(c, desc, Box(box.x + 14, box.y + 34, box.w - 24, box.h - 68), size=12, color=PALETTE["slate"])
        c.setFillColor(PALETTE["muted"])
        c.setFont("Helvetica", 9)
        c.drawString(box.x + 14, box.y + 11, src)


def slide_05_solution(ctx: SlideCtx) -> None:
    c = ctx.c
    area = header(
        ctx,
        "Our Solution",
        "One platform, two engines: consumer demand + pro operations.",
        bg_top=HexColor("#F8FAFC"),
        bg_bottom=HexColor("#EEF2FF"),
        accent=PALETTE["indigo"],
        dark=False,
        tag="product",
    )

    top = Box(area.x, area.y + area.h * 0.40, area.w, area.h * 0.60)
    bottom = Box(area.x, area.y, area.w, area.h * 0.36)

    card(c, top, fill=white)
    c.setFillColor(PALETTE["ink"])
    c.setFont("Helvetica-Bold", 20)
    c.drawString(top.x + 18, top.y + top.h - 28, "Consumer modules (visuals from codebase assets)")

    icon_map = [
        ("Home", "home.png"),
        ("Food", "food.png"),
        ("Laundry", "laundry.png"),
        ("Ride", "car.png"),
        ("Doctor", "doctor.png"),
        ("Hotel", "hotel.png"),
        ("Pharmacy", "pharmacy.png"),
        ("Shopping", "shopping.png"),
    ]

    start_x = top.x + 20
    y = top.y + 22
    cell_w = (top.w - 40 - 7 * 8) / 8
    for i, (label, icon) in enumerate(icon_map):
        x = start_x + i * (cell_w + 8)
        card(c, Box(x, y, cell_w, top.h - 58), fill=HexColor("#F8FAFC"), radius=10)
        p = ROOT / "assets" / "icons" / icon
        if p.exists():
            c.drawImage(str(p), x + (cell_w - 44) / 2, y + 38, width=44, height=44, mask="auto")
        c.setFillColor(PALETTE["ink"])
        c.setFont("Helvetica-Bold", 10)
        c.drawCentredString(x + cell_w / 2, y + 20, label)

    card(c, bottom, fill=white)
    c.setFillColor(PALETTE["ink"])
    c.setFont("Helvetica-Bold", 19)
    c.drawString(bottom.x + 18, bottom.y + bottom.h - 26, "What this enables")
    bullets_fit(
        c,
        [
            "Cross-category service discovery and booking in one app shell.",
            "Queue-based operational execution for providers, delivery teams and riders.",
            "A single brand experience that can scale city-by-city with shared infrastructure.",
        ],
        Box(bottom.x + 18, bottom.y + 16, bottom.w - 36, bottom.h - 50),
        max_size=12.5,
    )


def slide_06_product_proof(ctx: SlideCtx) -> None:
    c = ctx.c
    area = header(
        ctx,
        "Product Proof from the Codebase",
        "Real implemented workflows, not concept-only mockups.",
        bg_top=HexColor("#082F49"),
        bg_bottom=HexColor("#0C4A6E"),
        accent=PALETTE["teal"],
        dark=True,
        tag="execution",
    )

    left = Box(area.x, area.y, area.w * 0.40, area.h)
    right = Box(area.x + area.w * 0.42, area.y, area.w * 0.58, area.h)

    card(c, left, fill=white)
    shot = ROOT / "flutter_01.png"
    if shot.exists():
        draw_image_cover(c, shot, Box(left.x + 12, left.y + 12, left.w - 24, left.h - 24))

    card(c, right, fill=white)
    c.setFillColor(PALETTE["ink"])
    c.setFont("Helvetica-Bold", 20)
    c.drawString(right.x + 18, right.y + right.h - 30, "Implemented capabilities")
    bullets_fit(
        c,
        [
            "Geo-enabled home service booking flow with map/location support.",
            "Structured booking parameters: date/time, urgency, shift durations, and service options.",
            "Dispatch-aware provider fallback logic to reduce booking failure.",
            "Pro queue state machine for service order progression and action labels.",
            "Role-specific route architecture for shop, provider, doctor, delivery, and rider personas.",
            "Hybrid backend pattern defined: Firebase + PostgreSQL for scalable transactional integrity.",
        ],
        Box(right.x + 18, right.y + 18, right.w - 36, right.h - 60),
        max_size=12.5,
    )


def slide_07_business_model(ctx: SlideCtx) -> None:
    c = ctx.c
    area = header(
        ctx,
        "Business Model",
        "Multiple monetization lanes designed for margin expansion over time.",
        bg_top=HexColor("#F0FDF4"),
        bg_bottom=HexColor("#DCFCE7"),
        accent=PALETTE["mint"],
        dark=False,
        tag="revenue",
    )

    a = Box(area.x, area.y, area.w * 0.52, area.h)
    b = Box(area.x + area.w * 0.54, area.y, area.w * 0.46, area.h)

    card(c, a, fill=white)
    c.setFillColor(PALETTE["ink"])
    c.setFont("Helvetica-Bold", 21)
    c.drawString(a.x + 18, a.y + a.h - 30, "Revenue stack")
    bullets_fit(
        c,
        [
            "Take-rate commissions on completed orders/bookings.",
            "Delivery and service fulfillment fees.",
            "Pro subscription layers for enhanced visibility and workflow tooling.",
            "Sponsored placement and in-app partner promotion.",
            "Future fintech monetization through payment-linked services.",
        ],
        Box(a.x + 18, a.y + 18, a.w - 36, a.h - 60),
    )

    card(c, b, fill=white)
    c.setFillColor(PALETTE["ink"])
    c.setFont("Helvetica-Bold", 21)
    c.drawString(b.x + 18, b.y + b.h - 30, "Economics logic")

    points = [
        ("Higher order frequency", 0.82, PALETTE["teal"]),
        ("Higher basket value", 0.64, PALETTE["sky"]),
        ("Lower idle time", 0.71, PALETTE["mint"]),
        ("Retention lift", 0.77, PALETTE["indigo"]),
    ]

    y = b.y + b.h - 70
    for label, pct, color in points:
        c.setFillColor(PALETTE["slate"])
        c.setFont("Helvetica", 11)
        c.drawString(b.x + 18, y + 6, label)
        c.setFillColor(PALETTE["soft"])
        c.roundRect(b.x + 18, y - 8, b.w - 52, 10, 4, stroke=0, fill=1)
        c.setFillColor(color)
        c.roundRect(b.x + 18, y - 8, (b.w - 52) * pct, 10, 4, stroke=0, fill=1)
        y -= 58

    c.setFillColor(PALETTE["muted"])
    c.setFont("Helvetica-Oblique", 9)
    c.drawString(b.x + 18, b.y + 14, "Bars show model directionality; replace with audited KPIs before final investor send.")


def slide_08_gtm(ctx: SlideCtx) -> None:
    c = ctx.c
    area = header(
        ctx,
        "Go-To-Market",
        "Density-first city launch playbook tailored to African urban operations.",
        bg_top=HexColor("#FFF7ED"),
        bg_bottom=HexColor("#FFEDD5"),
        accent=PALETTE["amber"],
        dark=False,
        tag="growth",
    )

    card(c, Box(area.x, area.y, area.w, area.h), fill=white)

    cols = 4
    gap = 12
    cw = (area.w - (cols + 1) * gap) / cols
    titles = [
        "1. Launch Zone",
        "2. Supply Reliability",
        "3. Demand Growth",
        "4. Replication",
    ]
    lines = [
        ["Start with one dense zone per city.", "Focus on high-frequency categories first."],
        ["Onboard verified providers.", "Use queue tooling to enforce SLA behavior."],
        ["Referral + neighborhood activation.", "Retention through reliability and transparency."],
        ["Expand categories after utilization proof.", "Copy operating playbook into new cities."],
    ]

    x = area.x + gap
    for i in range(cols):
        box = Box(x, area.y + gap, cw, area.h - 2 * gap)
        card(c, box, fill=HexColor("#F8FAFC"), radius=10)
        c.setFillColor(PALETTE["amber"])
        c.setFont("Helvetica-Bold", 14)
        c.drawString(box.x + 10, box.y + box.h - 22, titles[i])
        bullets_fit(c, lines[i], Box(box.x + 10, box.y + 14, box.w - 20, box.h - 42), max_size=11.5)
        x += cw + gap


def slide_09_moat(ctx: SlideCtx) -> None:
    c = ctx.c
    area = header(
        ctx,
        "Competitive Edge & Defensibility",
        "Our advantage compounds as transactions and provider operations scale.",
        bg_top=HexColor("#ECFEFF"),
        bg_bottom=HexColor("#E0F2FE"),
        accent=PALETTE["sky"],
        dark=False,
        tag="moat",
    )

    left = Box(area.x, area.y, area.w * 0.48, area.h)
    right = Box(area.x + area.w * 0.50, area.y, area.w * 0.50, area.h)

    card(c, left, fill=white)
    c.setFillColor(PALETTE["ink"])
    c.setFont("Helvetica-Bold", 19)
    c.drawString(left.x + 18, left.y + left.h - 28, "Why a generic app cannot copy this fast")
    bullets_fit(
        c,
        [
            "Multi-vertical demand aggregation improves dispatch efficiency.",
            "Provider-side workflow lock-in via queue operations and schedules.",
            "Localized trust system (verification + predictable status progression).",
            "Shared infrastructure lowers expansion cost per new category/city.",
        ],
        Box(left.x + 18, left.y + 18, left.w - 36, left.h - 58),
    )

    card(c, right, fill=white)
    c.setFillColor(PALETTE["ink"])
    c.setFont("Helvetica-Bold", 19)
    c.drawString(right.x + 18, right.y + right.h - 28, "Operating system view")

    layers = [
        ("Demand Layer", "Consumer app and category entry points", HexColor("#DBEAFE")),
        ("Execution Layer", "Provider and delivery queue operations", HexColor("#DCFCE7")),
        ("Data Layer", "Transactions, preferences, and dispatch intelligence", HexColor("#FCE7F3")),
    ]
    y = right.y + right.h - 80
    for title, desc, bg in layers:
        b = Box(right.x + 18, y, right.w - 36, 70)
        card(c, b, fill=bg, radius=10)
        c.setFillColor(PALETTE["ink"])
        c.setFont("Helvetica-Bold", 13)
        c.drawString(b.x + 12, b.y + 44, title)
        c.setFont("Helvetica", 11)
        c.setFillColor(PALETTE["slate"])
        c.drawString(b.x + 12, b.y + 24, desc)
        y -= 90


def slide_10_roadmap(ctx: SlideCtx) -> None:
    c = ctx.c
    area = header(
        ctx,
        "18-Month Roadmap",
        "Milestones aligned to product depth, reliability, and city expansion.",
        bg_top=HexColor("#EEF2FF"),
        bg_bottom=HexColor("#E0E7FF"),
        accent=PALETTE["indigo"],
        dark=False,
        tag="milestones",
    )

    card(c, Box(area.x, area.y, area.w, area.h), fill=white)
    periods = [
        ("Q2-Q3 2026", "Execution hardening", ["Stabilize booking->dispatch->completion quality.", "Launch provider reliability scorecards."]),
        ("Q4 2026", "Category depth", ["Scale top-performing categories.", "Improve repeat order mechanics."]),
        ("H1 2027", "City expansion", ["Replicate playbook in 2-3 target cities.", "Strengthen partner acquisition channels."]),
        ("H2 2027", "Efficiency", ["Push margin optimization and retention gains.", "Prepare for follow-on financing narrative."]),
    ]

    gap = 12
    w = (area.w - 5 * gap) / 4
    x = area.x + gap
    for i, (period, title, pts) in enumerate(periods):
        b = Box(x, area.y + gap, w, area.h - 2 * gap)
        card(c, b, fill=HexColor("#F8FAFC"), radius=10)
        c.setFillColor(PALETTE["indigo"])
        c.setFont("Helvetica-Bold", 11)
        c.drawString(b.x + 10, b.y + b.h - 20, period)
        c.setFillColor(PALETTE["ink"])
        c.setFont("Helvetica-Bold", 14)
        c.drawString(b.x + 10, b.y + b.h - 42, title)
        bullets_fit(c, pts, Box(b.x + 10, b.y + 16, b.w - 20, b.h - 62), max_size=11.0)
        if i < 3:
            c.setStrokeColor(PALETTE["muted"])
            c.setLineWidth(1.2)
            c.line(b.x + b.w + 2, b.y + b.h / 2, b.x + b.w + 10, b.y + b.h / 2)
        x += w + gap


def slide_11_finance_ask(ctx: SlideCtx) -> None:
    c = ctx.c
    area = header(
        ctx,
        "Fundraise Ask",
        "Capital to convert product readiness into scaled city operations.",
        bg_top=HexColor("#082F49"),
        bg_bottom=HexColor("#0E7490"),
        accent=PALETTE["mint"],
        dark=True,
        tag="funding",
    )

    left = Box(area.x, area.y, area.w * 0.38, area.h)
    right = Box(area.x + area.w * 0.40, area.y, area.w * 0.60, area.h)

    card(c, left, fill=white)
    c.setFillColor(PALETTE["ink"])
    c.setFont("Helvetica-Bold", 22)
    c.drawString(left.x + 18, left.y + left.h - 32, "Target Raise")
    c.setFillColor(PALETTE["teal"])
    c.setFont("Helvetica-Bold", 40)
    c.drawString(left.x + 18, left.y + left.h - 84, "US$1.2M")
    c.setFillColor(PALETTE["muted"])
    c.setFont("Helvetica", 11)
    c.drawString(left.x + 18, left.y + left.h - 106, "Pre-seed / Seed (editable)")

    bullets_fit(
        c,
        [
            "Runway objective: 18 months.",
            "Primary KPI focus: reliability, retention, and city-level density.",
            "Round terms and valuation to be finalized with advisors.",
        ],
        Box(left.x + 18, left.y + 16, left.w - 36, left.h - 130),
        max_size=11.5,
    )

    card(c, right, fill=white)
    c.setFillColor(PALETTE["ink"])
    c.setFont("Helvetica-Bold", 22)
    c.drawString(right.x + 18, right.y + right.h - 32, "Use of funds")

    uses = [
        ("City operations + supply onboarding", 40, PALETTE["teal"]),
        ("Product and engineering", 27, PALETTE["sky"]),
        ("Demand growth + retention", 21, PALETTE["mint"]),
        ("Compliance, finance, contingency", 12, PALETTE["amber"]),
    ]
    y = right.y + right.h - 70
    for label, pct, color in uses:
        c.setFillColor(PALETTE["slate"])
        c.setFont("Helvetica", 11)
        c.drawString(right.x + 18, y + 8, label)
        c.setFillColor(PALETTE["soft"])
        c.roundRect(right.x + 18, y - 8, right.w - 120, 12, 5, stroke=0, fill=1)
        c.setFillColor(color)
        c.roundRect(right.x + 18, y - 8, (right.w - 120) * (pct / 100), 12, 5, stroke=0, fill=1)
        c.setFillColor(PALETTE["ink"])
        c.setFont("Helvetica-Bold", 11)
        c.drawRightString(right.x + right.w - 18, y + 8, f"{pct}%")
        y -= 56

    c.setFillColor(PALETTE["muted"])
    c.setFont("Helvetica-Oblique", 9)
    c.drawString(right.x + 18, right.y + 14, "Percent split is a planning baseline and should reflect your final operating model.")


def slide_12_closing(ctx: SlideCtx) -> None:
    c = ctx.c
    gradient_bg(c, PALETTE["midnight"], PALETTE["navy"])

    c.setFillColor(white)
    c.setFont("Helvetica-Bold", 38)
    c.drawString(54, PAGE_H - 96, "Thank You")
    c.setFont("Helvetica", 17)
    c.drawString(54, PAGE_H - 126, "We are building the service infrastructure layer for modern African cities.")

    panel = Box(54, 190, 520, 220)
    c.setFillColor(Color(1, 1, 1, alpha=0.10))
    c.roundRect(panel.x, panel.y, panel.w, panel.h, 14, stroke=0, fill=1)
    c.setFillColor(white)
    c.setFont("Helvetica-Bold", 15)
    c.drawString(panel.x + 16, panel.y + panel.h - 28, "Founder contact")
    c.setFont("Helvetica", 13)
    c.drawString(panel.x + 16, panel.y + panel.h - 56, "Name: [Founder Name]")
    c.drawString(panel.x + 16, panel.y + panel.h - 80, "Email: [your.email@company.com]")
    c.drawString(panel.x + 16, panel.y + panel.h - 104, "Phone/WhatsApp: [+xxx xxx xxx]")
    c.drawString(panel.x + 16, panel.y + panel.h - 128, "HQ: Djibouti | Expansion: East/West Africa")

    c.setFont("Helvetica-Bold", 11)
    c.drawString(panel.x + 16, panel.y + 58, "Reference backbone for this deck")
    c.setFont("Helvetica", 9)
    c.drawString(panel.x + 16, panel.y + 40, "Sequoia 'Writing a Business Plan'; YC 'How to Design a Better Pitch Deck';")
    c.drawString(panel.x + 16, panel.y + 26, "GSMA Mobile Economy Africa 2025; GSMA Mobile Money 2026; World Bank AfCFTA overview.")

    img = ROOT / "assets/images/banners/home-service-banner.png"
    frame = Box(PAGE_W - 360, 88, 300, 430)
    c.setFillColor(Color(1, 1, 1, alpha=0.10))
    c.roundRect(frame.x - 8, frame.y - 8, frame.w + 16, frame.h + 16, 16, stroke=0, fill=1)
    if img.exists():
        draw_image_cover(c, img, frame)

    c.setFillColor(Color(1, 1, 1, alpha=0.10))
    c.rect(0, 0, PAGE_W, 22, stroke=0, fill=1)
    c.setFillColor(Color(1, 1, 1, alpha=0.82))
    c.setFont("Helvetica", 9)
    c.drawString(16, 7, "EdaLab | Confidential Investor Deck | April 2026")
    c.drawRightString(PAGE_W - 16, 7, f"{ctx.page}/{ctx.total}")


def build() -> Path:
    OUTPUT_PDF.parent.mkdir(parents=True, exist_ok=True)
    c = canvas.Canvas(str(OUTPUT_PDF), pagesize=(PAGE_W, PAGE_H))

    slides = [
        slide_01_cover,
        slide_02_narrative,
        slide_03_problem,
        slide_04_why_now,
        slide_05_solution,
        slide_06_product_proof,
        slide_07_business_model,
        slide_08_gtm,
        slide_09_moat,
        slide_10_roadmap,
        slide_11_finance_ask,
        slide_12_closing,
    ]

    total = len(slides)
    for idx, draw in enumerate(slides, start=1):
        draw(SlideCtx(c=c, page=idx, total=total))
        c.showPage()

    c.save()
    return OUTPUT_PDF


if __name__ == "__main__":
    out = build()
    print(f"Created: {out}")
