from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Sequence

from PIL import Image
from reportlab.lib.colors import Color, HexColor, white
from reportlab.lib.units import inch
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfgen import canvas


ROOT = Path(__file__).resolve().parents[1]
OUT_MAIN = ROOT / "docs" / "EdaLab_Investor_Pitch_Deck_2026.pdf"
OUT_V3 = ROOT / "docs" / "EdaLab_Investor_Pitch_Deck_2026_v3_superapp.pdf"
BUILD = ROOT / "build" / "pitch_deck_assets"
BUILD.mkdir(parents=True, exist_ok=True)

W = 13.333 * inch
H = 7.5 * inch
MARGIN = 42
HEADER_H = 118
FOOTER_H = 24

C = {
    "bg_dark_1": HexColor("#041827"),
    "bg_dark_2": HexColor("#0B2D45"),
    "bg_light_1": HexColor("#F8FAFC"),
    "bg_light_2": HexColor("#E2E8F0"),
    "ink": HexColor("#0F172A"),
    "slate": HexColor("#334155"),
    "muted": HexColor("#64748B"),
    "teal": HexColor("#0EA5A0"),
    "green": HexColor("#10B981"),
    "lime": HexColor("#84CC16"),
    "amber": HexColor("#F59E0B"),
    "sky": HexColor("#0284C7"),
    "panel": HexColor("#FFFFFF"),
    "soft": HexColor("#E2E8F0"),
}


@dataclass
class Slide:
    c: canvas.Canvas
    n: int
    total: int


@dataclass
class Box:
    x: float
    y: float
    w: float
    h: float


def mix(a: Color, b: Color, t: float) -> Color:
    return Color(
        a.red + (b.red - a.red) * t,
        a.green + (b.green - a.green) * t,
        a.blue + (b.blue - a.blue) * t,
    )


def grad(c: canvas.Canvas, top: Color, bottom: Color) -> None:
    steps = 130
    band = H / steps
    for i in range(steps):
        t = i / max(steps - 1, 1)
        c.setFillColor(mix(top, bottom, t))
        c.rect(0, H - (i + 1) * band, W, band + 1, stroke=0, fill=1)


def wrap(text: str, font: str, size: float, width: float) -> list[str]:
    words = text.split()
    if not words:
        return []
    lines = []
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


def draw_text(c: canvas.Canvas, text: str, box: Box, *, font="Helvetica", size=12, color=C["ink"]) -> float:
    lines = wrap(text, font, size, box.w)
    leading = size * 1.32
    y = box.y + box.h
    c.setFillColor(color)
    c.setFont(font, size)
    for ln in lines:
        if y - leading < box.y:
            break
        c.drawString(box.x, y - leading, ln)
        y -= leading
    return y


def bullets_height(items: Sequence[str], width: float, size: float) -> float:
    leading = size * 1.28
    h = 0.0
    for it in items:
        h += len(wrap(it, "Helvetica", size, width - 16)) * leading + size * 0.5
    return h


def draw_bullets(c: canvas.Canvas, items: Sequence[str], box: Box, *, max_size=14.0, min_size=10.5, bullet=C["teal"], color=C["ink"]) -> float:
    size = max_size
    while size >= min_size and bullets_height(items, box.w, size) > box.h:
        size -= 0.5
    leading = size * 1.28
    y = box.y + box.h
    c.setFont("Helvetica", size)

    for it in items:
        lines = wrap(it, "Helvetica", size, box.w - 16)
        if not lines:
            continue
        need = len(lines) * leading + size * 0.5
        if y - need < box.y:
            break
        c.setFillColor(bullet)
        c.circle(box.x + 4, y - size * 0.55, 2.8, stroke=0, fill=1)
        c.setFillColor(color)
        c.drawString(box.x + 12, y - size, lines[0])
        yy = y - leading
        for ln in lines[1:]:
            c.drawString(box.x + 12, yy - size, ln)
            yy -= leading
        y = yy - size * 0.5
    return size


def card(c: canvas.Canvas, b: Box, *, fill=white, radius=12) -> None:
    c.setFillColor(fill)
    c.roundRect(b.x, b.y, b.w, b.h, radius, stroke=0, fill=1)


def crop_to(src: Path, dst: Path, ratio: float) -> None:
    with Image.open(src) as im:
        im = im.convert("RGB")
        w, h = im.size
        r = w / h
        if r > ratio:
            nw = int(h * ratio)
            x = (w - nw) // 2
            im = im.crop((x, 0, x + nw, h))
        else:
            nh = int(w / ratio)
            y = (h - nh) // 2
            im = im.crop((0, y, w, y + nh))
        im.save(dst, "PNG")


def draw_cover_img(c: canvas.Canvas, src: Path, b: Box) -> None:
    tmp = BUILD / f"crop_{src.stem}_{int(b.w)}x{int(b.h)}.png"
    crop_to(src, tmp, b.w / b.h)
    c.drawImage(str(tmp), b.x, b.y, width=b.w, height=b.h, preserveAspectRatio=False, mask="auto")


def header(sl: Slide, title: str, subtitle: str, *, dark: bool, accent: Color, tag: str, top: Color, bottom: Color) -> Box:
    c = sl.c
    grad(c, top, bottom)

    deco = Color(1, 1, 1, alpha=0.08) if dark else Color(1, 1, 1, alpha=0.35)
    c.setFillColor(deco)
    c.circle(W - 90, H - 35, 72, stroke=0, fill=1)
    c.circle(W - 155, H - 82, 40, stroke=0, fill=1)

    c.setFillColor(Color(1, 1, 1, alpha=0.16) if dark else HexColor("#DBEAFE"))
    c.roundRect(MARGIN, H - 33, 250, 18, 7, stroke=0, fill=1)
    c.setFillColor(white if dark else C["sky"])
    c.setFont("Helvetica-Bold", 8.5)
    c.drawString(MARGIN + 9, H - 26, tag.upper())

    c.setFillColor(white if dark else C["ink"])
    c.setFont("Helvetica-Bold", 31)
    c.drawString(MARGIN, H - 66, title)
    c.setFillColor(Color(1, 1, 1, alpha=0.9) if dark else C["slate"])
    c.setFont("Helvetica", 13)
    c.drawString(MARGIN, H - 88, subtitle)

    c.setFillColor(accent)
    c.rect(MARGIN, H - 98, 220, 4, stroke=0, fill=1)

    c.setFillColor(Color(1, 1, 1, alpha=0.10) if dark else Color(0, 0, 0, alpha=0.05))
    c.rect(0, 0, W, FOOTER_H, stroke=0, fill=1)
    c.setFillColor(Color(1, 1, 1, alpha=0.82) if dark else C["muted"])
    c.setFont("Helvetica", 9)
    c.drawString(16, 8, "EdaLab | Confidential | April 2026")
    c.drawRightString(W - 16, 8, f"{sl.n}/{sl.total}")

    return Box(MARGIN, FOOTER_H + 10, W - MARGIN * 2, H - HEADER_H - FOOTER_H - 14)


def s1(sl: Slide) -> None:
    c = sl.c
    grad(c, C["bg_dark_1"], C["bg_dark_2"])

    c.setFillColor(Color(1, 1, 1, alpha=0.08))
    c.circle(W - 65, H - 18, 84, stroke=0, fill=1)
    c.circle(W - 170, H - 92, 58, stroke=0, fill=1)

    c.setFillColor(white)
    c.setFont("Helvetica-Bold", 48)
    c.drawString(52, H - 98, "EdaLab")
    c.setFont("Helvetica-Bold", 25)
    c.drawString(52, H - 132, "Africa's Grab/Gojek-Style Super App Opportunity")
    c.setFont("Helvetica", 14)
    c.drawString(52, H - 156, "Built for high-frequency services + trusted local fulfillment")

    banner = ROOT / "assets/images/banners/banner.png"
    if banner.exists():
        b = Box(52, 120, 530, 240)
        c.setFillColor(Color(1, 1, 1, alpha=0.12))
        c.roundRect(b.x - 4, b.y - 4, b.w + 8, b.h + 8, 14, stroke=0, fill=1)
        draw_cover_img(c, banner, b)

    shot = ROOT / "flutter_01.png"
    frame = Box(W - 290, 66, 210, 470)
    c.setFillColor(Color(1, 1, 1, alpha=0.10))
    c.roundRect(frame.x - 9, frame.y - 9, frame.w + 18, frame.h + 18, 28, stroke=0, fill=1)
    c.setFillColor(white)
    c.roundRect(frame.x, frame.y, frame.w, frame.h, 24, stroke=0, fill=1)
    if shot.exists():
        draw_cover_img(c, shot, Box(frame.x + 10, frame.y + 10, frame.w - 20, frame.h - 20))

    c.setFillColor(Color(1, 1, 1, alpha=0.16))
    c.roundRect(52, 56, 570, 46, 10, stroke=0, fill=1)
    c.setFillColor(white)
    c.setFont("Helvetica", 12.5)
    c.drawString(66, 73, "Investor deck strategy: adapt proven Asian super app playbooks to African city dynamics")

    c.setFillColor(Color(1, 1, 1, alpha=0.10))
    c.rect(0, 0, W, FOOTER_H, stroke=0, fill=1)
    c.setFillColor(Color(1, 1, 1, alpha=0.82))
    c.setFont("Helvetica", 9)
    c.drawString(16, 8, "EdaLab | Confidential | April 2026")
    c.drawRightString(W - 16, 8, f"{sl.n}/{sl.total}")


def s2(sl: Slide) -> None:
    c = sl.c
    area = header(sl, "What We Borrowed From Grab & Gojek", "Playbook principles, adapted for African markets.", dark=False, accent=C["green"], tag="superapp dna", top=HexColor("#F0FDF4"), bottom=HexColor("#DCFCE7"))

    card(c, Box(area.x, area.y, area.w, area.h), fill=white)
    pillars = [
        "Start with a high-frequency wedge, then layer adjacent services.",
        "Win on reliability, not just discounts: ETA clarity + service trust.",
        "Build dense city zones before expanding geography.",
        "Unify consumer demand and provider operations in one system.",
        "Turn transactions into a retention flywheel across verticals.",
    ]
    c.setFillColor(C["ink"])
    c.setFont("Helvetica-Bold", 22)
    c.drawString(area.x + 20, area.y + area.h - 34, "Super App Playbook")
    draw_bullets(c, pillars, Box(area.x + 20, area.y + 20, area.w - 40, area.h - 68), max_size=15)


def s3(sl: Slide) -> None:
    c = sl.c
    area = header(sl, "The African Gap", "Essential services remain fragmented, inconsistent, and hard to trust.", dark=False, accent=C["amber"], tag="problem", top=C["bg_light_1"], bottom=C["bg_light_2"])

    w = (area.w - 14) / 2
    left = Box(area.x, area.y, w, area.h)
    right = Box(area.x + w + 14, area.y, w, area.h)
    card(c, left)
    card(c, right)

    c.setFillColor(C["ink"])
    c.setFont("Helvetica-Bold", 20)
    c.drawString(left.x + 18, left.y + left.h - 30, "Consumers")
    draw_bullets(c, [
        "Too many apps/channels for daily services.",
        "Price and service quality are inconsistent.",
        "Weak visibility from booking to completion.",
        "Low confidence reduces repeat usage.",
    ], Box(left.x + 18, left.y + 18, left.w - 36, left.h - 60))

    c.setFillColor(C["ink"])
    c.setFont("Helvetica-Bold", 20)
    c.drawString(right.x + 18, right.y + right.h - 30, "Providers")
    draw_bullets(c, [
        "Demand is fragmented and unpredictable.",
        "Operations are mostly manual.",
        "No robust queue to manage job lifecycles.",
        "Idle time is high, earnings are volatile.",
    ], Box(right.x + 18, right.y + 18, right.w - 36, right.h - 60))


def s4(sl: Slide) -> None:
    c = sl.c
    area = header(sl, "EdaLab Solution", "One brand, many everyday needs, with operational depth.", dark=False, accent=C["teal"], tag="solution", top=HexColor("#ECFEFF"), bottom=HexColor("#E0F2FE"))

    top = Box(area.x, area.y + area.h * 0.38, area.w, area.h * 0.62)
    bottom = Box(area.x, area.y, area.w, area.h * 0.34)
    card(c, top)
    card(c, bottom)

    c.setFillColor(C["ink"])
    c.setFont("Helvetica-Bold", 20)
    c.drawString(top.x + 18, top.y + top.h - 30, "Current product surface")

    icons = ["home.png", "food.png", "laundry.png", "car.png", "doctor.png", "hotel.png", "pharmacy.png", "shopping.png"]
    labels = ["Home", "Food", "Laundry", "Ride", "Doctor", "Hotel", "Pharmacy", "Shopping"]
    x0 = top.x + 18
    cell_w = (top.w - 36 - 7 * 8) / 8
    y = top.y + 26
    for i, (ic, lb) in enumerate(zip(icons, labels)):
        x = x0 + i * (cell_w + 8)
        card(c, Box(x, y, cell_w, top.h - 60), fill=HexColor("#F8FAFC"), radius=10)
        p = ROOT / "assets/icons" / ic
        if p.exists():
            c.drawImage(str(p), x + (cell_w - 46) / 2, y + 34, width=46, height=46, mask="auto")
        c.setFillColor(C["ink"])
        c.setFont("Helvetica-Bold", 10)
        c.drawCentredString(x + cell_w / 2, y + 18, lb)

    draw_bullets(c, [
        "Consumer app + Pro app architecture gives both demand and execution control.",
        "Designed to scale like Asian super apps, but tuned for local African operational realities.",
        "Category expansion is modular once trust and reliability are established in a city.",
    ], Box(bottom.x + 18, bottom.y + 14, bottom.w - 36, bottom.h - 28), max_size=12.5)


def s5(sl: Slide) -> None:
    c = sl.c
    area = header(sl, "Product Proof", "Real codebase workflows already implemented.", dark=True, accent=C["teal"], tag="execution", top=HexColor("#082F49"), bottom=HexColor("#0C4A6E"))

    left = Box(area.x, area.y, area.w * 0.40, area.h)
    right = Box(area.x + area.w * 0.42, area.y, area.w * 0.58, area.h)
    card(c, left)
    card(c, right)

    shot = ROOT / "flutter_01.png"
    if shot.exists():
        draw_cover_img(c, shot, Box(left.x + 12, left.y + 12, left.w - 24, left.h - 24))

    c.setFillColor(C["ink"])
    c.setFont("Helvetica-Bold", 20)
    c.drawString(right.x + 18, right.y + right.h - 30, "Implemented today")
    draw_bullets(c, [
        "Geo-enabled booking flow with map/location support.",
        "Scheduling, urgency, and service option controls in booking UI.",
        "Provider dispatch/fallback logic for better fill rates.",
        "Pro queue status transitions from pending to completed.",
        "Role-specific routing for provider, delivery, rider, doctor, and shop.",
    ], Box(right.x + 18, right.y + 16, right.w - 36, right.h - 56), max_size=12.8)


def s6(sl: Slide) -> None:
    c = sl.c
    area = header(sl, "Why This Can Win", "Super app economics improve with density and repeat behavior.", dark=False, accent=C["lime"], tag="moat", top=HexColor("#F0FDF4"), bottom=HexColor("#DCFCE7"))

    a = Box(area.x, area.y, area.w * 0.52, area.h)
    b = Box(area.x + area.w * 0.54, area.y, area.w * 0.46, area.h)
    card(c, a)
    card(c, b)

    c.setFillColor(C["ink"])
    c.setFont("Helvetica-Bold", 20)
    c.drawString(a.x + 18, a.y + a.h - 30, "Compounding advantages")
    draw_bullets(c, [
        "More orders -> better dispatch -> faster ETA -> higher retention.",
        "Shared infra across categories lowers marginal expansion cost.",
        "Provider tools raise service quality and reduce churn on supply side.",
        "Cross-vertical user behavior improves recommendations and LTV.",
    ], Box(a.x + 18, a.y + 18, a.w - 36, a.h - 60))

    c.setFillColor(C["ink"])
    c.setFont("Helvetica-Bold", 20)
    c.drawString(b.x + 18, b.y + b.h - 30, "Monetization lanes")
    draw_bullets(c, [
        "Commission on completed services/orders.",
        "Delivery and convenience fees.",
        "Pro subscriptions and premium placement.",
        "Future fintech/payment layers.",
    ], Box(b.x + 18, b.y + 120, b.w - 36, b.h - 162), max_size=12)

    # mini bars
    y = b.y + 92
    bars = [("Frequency", 0.80, C["teal"]), ("Retention", 0.74, C["sky"]), ("Utilization", 0.68, C["green"])]
    for label, v, col in bars:
        c.setFillColor(C["slate"])
        c.setFont("Helvetica", 10)
        c.drawString(b.x + 18, y + 6, label)
        c.setFillColor(C["soft"])
        c.roundRect(b.x + 78, y, b.w - 110, 9, 4, stroke=0, fill=1)
        c.setFillColor(col)
        c.roundRect(b.x + 78, y, (b.w - 110) * v, 9, 4, stroke=0, fill=1)
        y -= 22


def s7(sl: Slide) -> None:
    c = sl.c
    area = header(sl, "Africa Market Timing", "Macro conditions now support super app scale-up.", dark=False, accent=C["sky"], tag="market", top=HexColor("#EEF2FF"), bottom=HexColor("#DBEAFE"))

    gap = 10
    w = (area.w - gap) / 2
    h = (area.h - gap) / 2
    boxes = [
        Box(area.x, area.y + h + gap, w, h),
        Box(area.x + w + gap, area.y + h + gap, w, h),
        Box(area.x, area.y, w, h),
        Box(area.x + w + gap, area.y, w, h),
    ]
    data = [
        ("416M", "Mobile internet users in Africa (2024).", "GSMA Mobile Economy Africa 2025", C["sky"]),
        ("$220B", "Mobile tech contribution to African GDP (2024).", "GSMA Mobile Economy Africa 2025", C["teal"]),
        ("$2T", "Mobile money transaction value (2025).", "GSMA SOI Mobile Money 2026", C["green"]),
        ("1.3B", "AfCFTA market population context.", "World Bank AfCFTA", C["amber"]),
    ]
    for b, (val, txt, src, col) in zip(boxes, data):
        card(c, b)
        c.setFillColor(col)
        c.rect(b.x, b.y + b.h - 6, b.w, 6, stroke=0, fill=1)
        c.setFillColor(C["ink"])
        c.setFont("Helvetica-Bold", 24)
        c.drawString(b.x + 14, b.y + b.h - 36, val)
        draw_text(c, txt, Box(b.x + 14, b.y + 34, b.w - 24, b.h - 66), size=12, color=C["slate"])
        c.setFillColor(C["muted"])
        c.setFont("Helvetica", 9)
        c.drawString(b.x + 14, b.y + 12, src)


def s8(sl: Slide) -> None:
    c = sl.c
    area = header(sl, "Go-To-Market", "Density-first rollout, then category expansion.", dark=False, accent=C["amber"], tag="gtm", top=HexColor("#FFF7ED"), bottom=HexColor("#FFEDD5"))

    card(c, Box(area.x, area.y, area.w, area.h))
    titles = ["1. Wedge", "2. Reliability", "3. Retention", "4. Replicate"]
    lines = [
        ["Launch high-frequency categories first.", "Own one dense zone before scaling out."],
        ["Train and verify supply-side partners.", "SLA-focused queue ops and status discipline."],
        ["Build habit loops with consistency.", "Cross-category nudges and bundled use cases."],
        ["Expand to adjacent cities.", "Reuse proven launch + ops playbook."],
    ]
    gap = 10
    cw = (area.w - 5 * gap) / 4
    x = area.x + gap
    for i in range(4):
        b = Box(x, area.y + gap, cw, area.h - 2 * gap)
        card(c, b, fill=HexColor("#F8FAFC"), radius=10)
        c.setFillColor(C["amber"])
        c.setFont("Helvetica-Bold", 14)
        c.drawString(b.x + 10, b.y + b.h - 21, titles[i])
        draw_bullets(c, lines[i], Box(b.x + 10, b.y + 14, b.w - 20, b.h - 42), max_size=11.2)
        x += cw + gap


def s9(sl: Slide) -> None:
    c = sl.c
    area = header(sl, "Operating Model", "Consumer app + Pro stack + hybrid backend data architecture.", dark=False, accent=C["teal"], tag="architecture", top=HexColor("#ECFEFF"), bottom=HexColor("#CCFBF1"))

    card(c, Box(area.x, area.y, area.w, area.h))
    layers = [
        ("Consumer App", "Multi-module user journeys and bookings", HexColor("#DBEAFE")),
        ("Pro Operations", "Queue handling, scheduling, execution, status transitions", HexColor("#DCFCE7")),
        ("Backend Core", "PostgreSQL truth + Firebase realtime projection", HexColor("#FCE7F3")),
    ]
    y = area.y + area.h - 86
    for title, desc, col in layers:
        b = Box(area.x + 60, y, area.w - 120, 72)
        card(c, b, fill=col, radius=10)
        c.setFillColor(C["ink"])
        c.setFont("Helvetica-Bold", 15)
        c.drawString(b.x + 14, b.y + 45, title)
        c.setFont("Helvetica", 12)
        c.setFillColor(C["slate"])
        c.drawString(b.x + 14, b.y + 24, desc)
        y -= 94

    c.setStrokeColor(C["muted"])
    c.setLineWidth(1.4)
    c.line(area.x + area.w / 2, area.y + area.h - 14, area.x + area.w / 2, area.y + 20)


def s10(sl: Slide) -> None:
    c = sl.c
    area = header(sl, "Roadmap", "12-18 month milestones toward institutional growth metrics.", dark=False, accent=C["lime"], tag="roadmap", top=HexColor("#F0FDF4"), bottom=HexColor("#DCFCE7"))

    card(c, Box(area.x, area.y, area.w, area.h))
    steps = [
        ("Q2-Q3 2026", "Core city reliability", ["Improve dispatch completion rates", "Operational SLA dashboards"]),
        ("Q4 2026", "Category depth", ["Scale top-performing modules", "Strengthen repeat behavior"]),
        ("H1 2027", "Geographic expansion", ["Roll into 2-3 additional cities", "Partner-led growth channels"]),
        ("H2 2027", "Efficiency & scale", ["Margin improvement programs", "Prepare for next financing"]),
    ]
    gap = 10
    cw = (area.w - 5 * gap) / 4
    x = area.x + gap
    for i, (p, t, pts) in enumerate(steps):
        b = Box(x, area.y + gap, cw, area.h - 2 * gap)
        card(c, b, fill=HexColor("#F8FAFC"), radius=10)
        c.setFillColor(C["green"])
        c.setFont("Helvetica-Bold", 10)
        c.drawString(b.x + 10, b.y + b.h - 20, p)
        c.setFillColor(C["ink"])
        c.setFont("Helvetica-Bold", 14)
        c.drawString(b.x + 10, b.y + b.h - 40, t)
        draw_bullets(c, pts, Box(b.x + 10, b.y + 14, b.w - 20, b.h - 58), max_size=11.0)
        x += cw + gap


def s11(sl: Slide) -> None:
    c = sl.c
    area = header(sl, "Fundraising Ask", "Capital to accelerate city density and expansion.", dark=True, accent=C["green"], tag="ask", top=HexColor("#052E2B"), bottom=HexColor("#0F766E"))

    left = Box(area.x, area.y, area.w * 0.38, area.h)
    right = Box(area.x + area.w * 0.40, area.y, area.w * 0.60, area.h)
    card(c, left)
    card(c, right)

    c.setFillColor(C["ink"])
    c.setFont("Helvetica-Bold", 22)
    c.drawString(left.x + 18, left.y + left.h - 34, "Target Round")
    c.setFillColor(C["teal"])
    c.setFont("Helvetica-Bold", 40)
    c.drawString(left.x + 18, left.y + left.h - 86, "US$1.2M")
    c.setFillColor(C["muted"])
    c.setFont("Helvetica", 11)
    c.drawString(left.x + 18, left.y + left.h - 108, "Pre-seed / Seed (editable)")
    draw_bullets(c, [
        "Runway target: 18 months.",
        "Focus: reliability, retention, and expansion readiness.",
        "Round terms to be finalized with advisors.",
    ], Box(left.x + 18, left.y + 16, left.w - 36, left.h - 132), max_size=11.4)

    c.setFillColor(C["ink"])
    c.setFont("Helvetica-Bold", 20)
    c.drawString(right.x + 18, right.y + right.h - 34, "Use of funds")
    use = [
        ("City operations + supply", 40, C["teal"]),
        ("Product & engineering", 27, C["sky"]),
        ("Growth & retention", 21, C["green"]),
        ("Legal/compliance buffer", 12, C["amber"]),
    ]
    y = right.y + right.h - 70
    for label, pct, col in use:
        c.setFillColor(C["slate"])
        c.setFont("Helvetica", 11)
        c.drawString(right.x + 18, y + 8, label)
        c.setFillColor(C["soft"])
        c.roundRect(right.x + 18, y - 8, right.w - 120, 11, 5, stroke=0, fill=1)
        c.setFillColor(col)
        c.roundRect(right.x + 18, y - 8, (right.w - 120) * (pct / 100), 11, 5, stroke=0, fill=1)
        c.setFillColor(C["ink"])
        c.setFont("Helvetica-Bold", 10)
        c.drawRightString(right.x + right.w - 18, y + 8, f"{pct}%")
        y -= 55


def s12(sl: Slide) -> None:
    c = sl.c
    grad(c, C["bg_dark_1"], C["bg_dark_2"])

    c.setFillColor(white)
    c.setFont("Helvetica-Bold", 38)
    c.drawString(54, H - 98, "Thank You")
    c.setFont("Helvetica", 16)
    c.drawString(54, H - 128, "Building Africa's next generation super app with operational excellence.")

    box = Box(54, 190, 540, 220)
    c.setFillColor(Color(1, 1, 1, alpha=0.10))
    c.roundRect(box.x, box.y, box.w, box.h, 14, stroke=0, fill=1)
    c.setFillColor(white)
    c.setFont("Helvetica-Bold", 15)
    c.drawString(box.x + 16, box.y + box.h - 28, "Founder contact")
    c.setFont("Helvetica", 13)
    c.drawString(box.x + 16, box.y + box.h - 56, "Name: [Founder Name]")
    c.drawString(box.x + 16, box.y + box.h - 80, "Email: [your.email@company.com]")
    c.drawString(box.x + 16, box.y + box.h - 104, "Phone/WhatsApp: [+xxx xxx xxx]")
    c.drawString(box.x + 16, box.y + box.h - 128, "Base: Djibouti | Expansion: Pan-Africa")

    c.setFont("Helvetica", 9)
    c.drawString(box.x + 16, box.y + 30, "References: GSMA Mobile Economy Africa 2025, GSMA Mobile Money 2026, World Bank AfCFTA,")
    c.drawString(box.x + 16, box.y + 17, "plus playbook inspiration from Grab/Gojek scaling patterns and Sequoia/YC deck structures.")

    img = ROOT / "assets/images/banners/home-service-banner.png"
    if img.exists():
        draw_cover_img(c, img, Box(W - 344, 88, 288, 430))

    c.setFillColor(Color(1, 1, 1, alpha=0.10))
    c.rect(0, 0, W, FOOTER_H, stroke=0, fill=1)
    c.setFillColor(Color(1, 1, 1, alpha=0.82))
    c.setFont("Helvetica", 9)
    c.drawString(16, 8, "EdaLab | Confidential | April 2026")
    c.drawRightString(W - 16, 8, f"{sl.n}/{sl.total}")


def build(out: Path) -> None:
    c = canvas.Canvas(str(out), pagesize=(W, H))
    slides = [s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12]
    total = len(slides)
    for i, fn in enumerate(slides, start=1):
        fn(Slide(c, i, total))
        c.showPage()
    c.save()


if __name__ == "__main__":
    OUT_V3.parent.mkdir(parents=True, exist_ok=True)
    build(OUT_V3)
    build(OUT_MAIN)
    print(f"Created: {OUT_V3}")
    print(f"Updated: {OUT_MAIN}")
