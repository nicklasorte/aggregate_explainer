"""Preview figure options for docs/PLAN_visualize_turn_off_list.md.

These are design previews, not paper figures. They exist so Nick can pick a
form for each step before the MATLAB versions are built (the paper's figures
come from MATLAB examples, per CLAUDE.md).

Every number comes from the published example 07 run: toy_offsets_db.csv is
5*norminv(draw_uniform_columns_rev1(1000, 16, 1)), exported from MATLAB
R2025b. Columns 1-6 are simulation 1 (inside stations), 7-12 and 13-16 are
simulation 2 (inside and outside stations).

Run:  MPLBACKEND=Agg python3 -I make_previews.py <dataviz-resources scripts dir>
"""
import dataclasses
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import Circle, Rectangle

sys.path.insert(0, sys.argv[1])
from onepager import THEMES, OnePager  # noqa: E402

HERE = Path(__file__).resolve().parent
OUT = HERE / "png"
OUT.mkdir(exist_ok=True)

T = dataclasses.replace(THEMES["ntia"], headline_pt=13, sub_pt=9.5, panel_title_pt=9.5,
                        label_pt=8.5, tick_pt=8.5, source_pt=8, margin_in=0.35)
DARK, BLUE, PURPLE, GRAY = T.text, T.accent, T.accent2, T.context
LIGHT = "#C9CBCE"
SRC = "Source: aggregate_explainer example 07 (illustrative numbers, 1,000 trials, seed 1)."

# ---------------------------------------------------------------- data
OFF = np.loadtxt(HERE / "toy_offsets_db.csv", delimiter=",")
INS = np.array([-98, -100, -102, -104, -106, -108.0])
OUTS = np.array([-110, -112, -114, -116.0])
LIM, PCT = -99.0, 80
RANKS = [str(i) for i in range(1, 7)]
OUT_LABELS = list("ABCD")


def fw(dbm):
    """dBm to femtowatts (1 fW = -120 dBm)."""
    return 10 ** ((np.asarray(dbm) + 120) / 10)


def dbm(fw_):
    return 10 * np.log10(np.asarray(fw_)) - 120


def after_k(p):
    """Aggregate (dBm) of the stations after the first k, for k = 0..n-1."""
    lin = fw(p)
    tail = np.cumsum(lin[..., ::-1], -1)[..., ::-1]
    return dbm(tail)


def cut(p):
    a = after_k(p)
    ok = np.c_[a <= LIM, np.ones(len(a), bool)]
    return np.argmax(ok, 1)


P1 = INS + OFF[:, :6]
SIZE = cut(P1)
ORDER_FREE = np.argsort(-P1, 1)
SIZE_FREE = cut(-np.sort(-P1, 1))
Q = int(np.ceil(np.percentile(SIZE, PCT, method="hazen")))   # MATLAB prctile
LIST = min(Q + 1, 6)
P2 = np.c_[INS + OFF[:, 6:12], OUTS + OFF[:, 12:]]
REM = P2[:, LIST:]
AGG = dbm(fw(REM).sum(1))
AGG_ALL = dbm(fw(P2).sum(1))
AGG_IN_ONLY = dbm(fw(P2[:, :6]).sum(1))
Q_AGG = np.percentile(AGG, PCT, method="hazen")
PASS = 100 * np.mean(AGG <= LIM)
MED_STAIR = after_k(INS)
MED_CUT = int(cut(INS[None])[0])
FIRST = [MED_CUT] + list(SIZE[:3])
DIST = np.bincount(SIZE, minlength=7) / 10
DIST_FREE = np.bincount(SIZE_FREE, minlength=7) / 10

assert abs(SIZE.mean() - 3.343) < 1e-9 and Q == 4 and LIST == 5
assert abs(Q_AGG - (-100.07)) < 0.01 and abs(PASS - 89.3) < 1e-9


# ---------------------------------------------------------------- helpers
def page(headline, subhead, alt, h=3.9, source=SRC):
    return OnePager(headline=headline, subhead=subhead, source=source, theme=T, layout="hero",
                    size=(6.5, h), alt=alt, gap_h_in=0.45, gap_w_in=0.45)


def axes(pg, nrows=1, ncols=1, grid="y", wr=None, hr=None, wspace=0.35, hspace=0.5,
         left_in=0.85, right_in=0.3):
    gs = pg.fig.add_gridspec(nrows, ncols, width_ratios=wr, height_ratios=hr, wspace=wspace,
                             hspace=hspace, left=left_in / pg._W, right=1 - right_in / pg._W,
                             top=pg._content_top, bottom=pg._content_bottom + 0.06)
    out = []
    for i in range(nrows):
        for j in range(ncols):
            ax = pg.fig.add_subplot(gs[i, j])
            style(ax, grid)
            out.append(ax)
    return out


def style(ax, grid="y"):
    for s in ("top", "right", "left"):
        ax.spines[s].set_visible(False)
    ax.spines["bottom"].set_color(GRAY)
    ax.tick_params(labelsize=T.tick_pt, color=GRAY, length=0, pad=3)
    if grid:
        ax.grid(axis=grid, color=T.grid, lw=0.7)
        ax.set_axisbelow(True)


def title(ax, s):
    ax.set_title(s, loc="left", fontsize=T.panel_title_pt, fontweight="bold", color=DARK, pad=6)


def limit_line(ax, axis="y", label=True, x=None):
    if axis == "y":
        ax.axhline(LIM, color=PURPLE, lw=1.2, ls=(0, (4, 2)))
        if label:
            ax.text(ax.get_xlim()[1] if x is None else x, LIM + 0.4, "Limit −99 dBm",
                    color=PURPLE, fontsize=8, fontweight="bold", ha="right", va="bottom")
    else:
        ax.axvline(LIM, color=PURPLE, lw=1.2, ls=(0, (4, 2)))


def save(pg, name):
    pg.save(str(OUT / name), formats=("png",), quiet=False)
    plt.close(pg.fig)
    print("wrote", name)


def stair(ax, p, hi=True, label_cut=True, color=None):
    a = after_k(p)
    k = np.arange(len(a))
    c = cut(p[None])[0]
    ax.step(np.r_[k, len(a)], np.r_[a, a[-1]], where="post", color=color or GRAY, lw=1.6)
    if hi and c < len(a):
        ax.plot(c, a[c], "o", color=BLUE, ms=6, zorder=5)
        if label_cut:
            ax.annotate(f"cut point {c}", (c, a[c]), (c + 0.25, a[c] - 2.2), fontsize=8,
                        color=BLUE, fontweight="bold")
    return c


# ---------------------------------------------------------------- step 1: ranking
def a1():
    pg = page("The order is set once: the strongest median power goes first",
              "Median received power at the radar, dBm per megahertz; ranks 1-6 inside the "
              "radius, A-D outside", "Horizontal bar chart of median power, ranks 1 to 6 in "
              "blue at the top, outside stations A to D in gray below.", h=4.6)
    ax, = axes(pg, grid="x")
    labels = [f"Rank {r}" for r in RANKS] + [f"Outside {o}" for o in OUT_LABELS]
    vals = np.r_[INS, OUTS]
    y = np.r_[np.arange(6), np.arange(4) + 6.8]
    base = -120
    ax.barh(y, vals - base, left=base, color=[BLUE] * 6 + [LIGHT] * 4, height=0.7)
    for yi, v in zip(y, vals):
        ax.text(v + 0.3, yi, f"{v:.0f}", va="center", fontsize=8, color=DARK)
    ax.set_yticks(y, labels)
    ax.invert_yaxis()
    ax.set_xlim(base, -94)
    ax.axvline(LIM, color=PURPLE, lw=1.2, ls=(0, (4, 2)))
    ax.text(LIM + 0.2, 10.4, "Limit", color=PURPLE, fontsize=8, fontweight="bold")
    ax.text(-119.5, 6.4, "Outside the radius: never on the list", fontsize=8, color=DARK,
            style="italic")
    ax.set_xlabel("dBm")
    save(pg, "A1_ranking_bars")


def a2():
    pg = page("Six base stations can go on the list; four outside the radius can't",
              "Sketch, not to scale. Dot size shows median power; numbers are the median rank",
              "Plan-view sketch: radar at center, circle for the candidate radius, six numbered "
              "dots inside and four lettered dots outside.", h=4.3)
    ax, = axes(pg, grid=None)
    ax.set_aspect("equal")
    ax.axis("off")
    ax.add_patch(Circle((0, 0), 1, fill=False, ec=GRAY, lw=1.2, ls=(0, (3, 2))))
    ax.text(-0.95, 0.95, "Candidate radius", color=DARK, fontsize=8, ha="right")
    ax.plot(0, 0, marker="^", ms=11, color=DARK)
    ax.text(0.12, -0.12, "Radar", ha="center", va="top", fontsize=8, color=DARK)
    ang_in = np.deg2rad([60, 150, 230, 300, 20, 110])
    r_in = [0.35, 0.45, 0.55, 0.6, 0.75, 0.85]
    for i, (a, r) in enumerate(zip(ang_in, r_in)):
        s = 60 + 14 * (INS[i] + 110)
        ax.scatter(r * np.cos(a), r * np.sin(a), s=s, color=BLUE, zorder=3)
        ax.text(r * np.cos(a), r * np.sin(a), RANKS[i], ha="center", va="center",
                color="white", fontsize=8, fontweight="bold", zorder=4)
    for o, a, r in zip(OUT_LABELS, np.deg2rad([40, 170, 250, 330]), [1.25, 1.3, 1.35, 1.4]):
        ax.scatter(r * np.cos(a), r * np.sin(a), s=110, color=LIGHT, zorder=3)
        ax.text(r * np.cos(a), r * np.sin(a), o, ha="center", va="center", color=DARK,
                fontsize=8, fontweight="bold", zorder=4)
    ax.set_xlim(-1.6, 1.6)
    ax.set_ylim(-1.5, 1.5)
    save(pg, "A2_plan_view")


def a3():
    shares = fw(INS) / fw(INS).sum() * 100
    pg = page(f"At the medians, rank 1 alone delivers {shares[0]:.0f}% of the total",
              "Share of the median aggregate from the six base stations inside the radius, "
              "linear power", "Waffle chart of 100 squares split by station; rank 1 has 39 "
              "squares, rank 6 has 4.", h=4.4)
    ax, = axes(pg, grid=None)
    ax.set_aspect("equal")
    ax.axis("off")
    counts = np.round(shares).astype(int)
    counts[0] += 100 - counts.sum()
    colors = [BLUE, "#3F5FA8", "#7F96D3", GRAY, "#6B6E72", "#B0B2B5"]
    k = 0
    for i, c in enumerate(counts):
        for _ in range(c):
            row, col = divmod(k, 10)
            ax.add_patch(Rectangle((col, 9 - row), 0.86, 0.86, color=colors[i]))
            k += 1
    for i, c in enumerate(counts):
        ax.add_patch(Rectangle((11.2, 8.6 - i * 1.5), 0.86, 0.86, color=colors[i]))
        ax.text(12.4, 9.03 - i * 1.5, f"Rank {i + 1}: {c}%", va="center", fontsize=9,
                color=DARK, fontweight="bold" if i == 0 else "normal")
    ax.set_xlim(-0.2, 17)
    ax.set_ylim(-0.3, 10.1)
    save(pg, "A3_share_waffle")


def a4():
    pg = page("Each step down the order adds less: the first three carry 80% of the power",
              "Cumulative share of the median aggregate as base stations are added in rank "
              "order, linear power", "Bar and line chart: cumulative share reaches 80% at rank 3.")
    ax, = axes(pg)
    shares = fw(INS) / fw(INS).sum() * 100
    cum = np.cumsum(shares)
    x = np.arange(1, 7)
    ax.bar(x, shares, color=[BLUE] * 3 + [LIGHT] * 3, width=0.6)
    ax.plot(x, cum, "-o", color=DARK, ms=4, lw=1.2)
    for xi, c in zip(x, cum):
        ax.text(xi, c + 3, f"{c:.0f}%", ha="center", fontsize=8, color=DARK)
    ax.set_xticks(x, [f"Rank {r}" for r in RANKS])
    ax.set_ylim(0, 112)
    ax.set_ylabel("% of median aggregate")
    save(pg, "A4_cumulative_share")


# ---------------------------------------------------------------- step 2: one trial
def b1():
    pg = page(f"Turn base stations off in order until the total is under the limit: "
              f"{MED_CUT} at the medians",
              "Aggregate from the base stations still on, dBm per megahertz, every input at "
              "its median", "Staircase chart: aggregate falls from −94.0 dBm with 0 off to "
              "−100.9 dBm with 3 off, crossing the −99 dBm limit.")
    ax, = axes(pg)
    stair(ax, INS)
    for k, a in enumerate(MED_STAIR):
        ax.text(k + 0.5, a + 0.35, f"{a:.1f}", ha="center", fontsize=8, color=DARK)
    ax.set_xlim(0, 6)
    ax.set_ylim(-110, -92)
    limit_line(ax, x=5.95)
    ax.set_xticks(np.arange(6) + 0.5, [f"{k} off" for k in range(6)])
    ax.set_ylabel("dBm")
    save(pg, "B1_staircase")


def b2():
    pg = page("In linear power, each base station is a block; remove blocks until the bar "
              "fits under the limit",
              "Power still on after each step, femtowatts (linear, so the blocks add); medians",
              "Stacked horizontal bars shrinking as ranks 1, 2, 3 are removed; the bar first "
              "fits under the limit line at 3 off.", h=4.2)
    ax, = axes(pg, grid="x")
    lin = fw(INS)
    shades = [BLUE, "#7F96D3", "#B4C2E6", GRAY, "#B0B2B5", LIGHT]
    for k in range(6):
        left = 0
        for j in range(k, 6):
            ax.barh(k, lin[j], left=left, color=shades[j], height=0.62, ec="white", lw=0.6)
            if k == 0:
                ax.text(left + lin[j] / 2, -0.55, RANKS[j], ha="center", fontsize=8,
                        color=DARK)
            left += lin[j]
        ax.text(left + 6, k, f"{left:.0f} fW", va="center", fontsize=8,
                color=BLUE if k == MED_CUT else DARK,
                fontweight="bold" if k == MED_CUT else "normal")
    ax.axvline(fw(LIM), color=PURPLE, lw=1.2, ls=(0, (4, 2)))
    ax.text(fw(LIM) + 4, 5.55, f"Limit {fw(LIM):.0f} fW (−99 dBm)", color=PURPLE, fontsize=8,
            fontweight="bold")
    ax.set_yticks(range(6), [f"{k} off" for k in range(6)])
    ax.invert_yaxis()
    ax.set_xlim(0, 460)
    ax.set_xlabel("femtowatts")
    save(pg, "B2_shrinking_blocks")


def b3():
    pg = page("A waterfall: each base station turned off takes its share away",
              "Aggregate power, femtowatts (linear), medians; bars are the power removed by "
              "each step", "Waterfall chart from 402 fW total, removing ranks 1 to 3 to reach "
              "81 fW, under the 126 fW limit.")
    ax, = axes(pg)
    lin = fw(INS)
    tot = lin.sum()
    ax.bar(0, tot, color=GRAY, width=0.6)
    ax.text(0, tot + 6, f"{tot:.0f}", ha="center", fontsize=8)
    level = tot
    for k in range(MED_CUT):
        ax.bar(k + 1, lin[k], bottom=level - lin[k], color=BLUE, width=0.6)
        ax.text(k + 1, level + 6, f"−{lin[k]:.0f}", ha="center", fontsize=8, color=BLUE,
                fontweight="bold")
        level -= lin[k]
    ax.bar(MED_CUT + 1, level, color=DARK, width=0.6)
    ax.text(MED_CUT + 1, level + 6, f"{level:.0f}", ha="center", fontsize=8)
    ax.axhline(fw(LIM), color=PURPLE, lw=1.2, ls=(0, (4, 2)))
    ax.text(-0.45, fw(LIM) + 6, "Limit 126 fW", color=PURPLE, fontsize=8, fontweight="bold",
            ha="left")
    ax.set_xticks(range(MED_CUT + 2), ["All on"] + [f"Rank {r} off" for r in RANKS[:MED_CUT]]
                  + ["Left on"])
    ax.set_ylim(0, 450)
    ax.set_ylabel("femtowatts")
    save(pg, "B3_waterfall")


def b4():
    pg = page("Storyboard: one row per step, until the total meets the limit",
              "Filled tile = turned off. Aggregate of the rest, dBm per megahertz; medians",
              "Grid of 6 tiles per row; rows add one more off tile each; the row with 3 off "
              "is highlighted as the first to meet the limit.", h=4.0)
    ax, = axes(pg, grid=None)
    ax.axis("off")
    for k in range(6):
        for j in range(6):
            off = j < k
            ax.add_patch(Rectangle((j, -k), 0.85, 0.75, color=DARK if off else LIGHT))
            if k == 0:
                ax.text(j + 0.42, 1.0, RANKS[j], ha="center", fontsize=8, color=DARK)
        ok = MED_STAIR[k] <= LIM
        first = k == MED_CUT
        ax.text(6.3, -k + 0.37, f"{MED_STAIR[k]:.1f} dBm" + ("  meets the limit: stop"
                                                            if first else ""),
                va="center", fontsize=8.5, color=BLUE if first else DARK,
                fontweight="bold" if first else "normal")
        ax.text(-0.3, -k + 0.37, f"{k} off", va="center", ha="right", fontsize=8.5,
                color=DARK)
    ax.add_patch(Rectangle((-1.3, -MED_CUT - 0.12), 12.3, 1.0, fill=False, ec=BLUE, lw=1.4))
    ax.text(-0.3, 1.0, "Rank", fontsize=8, color=DARK, ha="right")
    ax.set_xlim(-1.5, 11.2)
    ax.set_ylim(-5.4, 1.8)
    save(pg, "B4_storyboard")


# ---------------------------------------------------------------- step 2 repeated: trials
def c1():
    pg = page(f"Same order in every trial; only the cut point moves: {FIRST[1]}, {FIRST[2]}, "
              f"and {FIRST[3]}",
              "Aggregate from the base stations still on, dBm per megahertz; x-axis is the "
              "number turned off, in the same order", "Four staircase panels: medians cut at "
              "3; trials 1, 2, 3 cut at 2, 4, 5.", h=3.6)
    axs = axes(pg, 1, 4, wspace=0.18)
    data = [INS] + [P1[i] for i in range(3)]
    names = ["Medians"] + [f"Trial {i + 1}" for i in range(3)]
    for i, (ax, p, n) in enumerate(zip(axs, data, names)):
        stair(ax, p, label_cut=False)
        c = cut(p[None])[0]
        title(ax, f"{n}: {c} off")
        ax.set_xlim(0, 6)
        ax.set_ylim(-112, -88)
        ax.axhline(LIM, color=PURPLE, lw=1.1, ls=(0, (4, 2)))
        ax.set_xticks([0.5, 2.5, 4.5], ["0", "2", "4"])
        if i:
            ax.set_yticklabels([])
        else:
            ax.set_ylabel("dBm")
    axs[-1].text(5.9, LIM + 0.5, "Limit", color=PURPLE, fontsize=8, fontweight="bold",
                 ha="right", va="bottom")
    save(pg, "C1_small_multiples")


def c2():
    n = 60
    pg = page("Sixty trials, sixty staircases: the crossing point spreads from 1 to 6",
              "Aggregate from the base stations still on, dBm per megahertz; gray lines are "
              "trials, blue is the medians; dots mark each trial's cut point",
              "Spaghetti plot of 60 staircases with the median staircase highlighted and "
              "crossing dots along the limit.")
    ax, = axes(pg)
    for i in range(n):
        a = after_k(P1[i])
        ax.step(np.r_[np.arange(6), 6], np.r_[a, a[-1]], where="post", color=LIGHT, lw=0.7)
        c = SIZE[i]
        if c < 6:
            ax.plot(c + 0.5 + np.random.default_rng(i).uniform(-0.3, 0.3), a[c], ".",
                    color=GRAY, ms=4)
    a = MED_STAIR
    ax.step(np.r_[np.arange(6), 6], np.r_[a, a[-1]], where="post", color=BLUE, lw=2)
    ax.text(0.1, a[0] + 0.6, "Medians", color=BLUE, fontsize=8, fontweight="bold")
    ax.set_xlim(0, 6)
    ax.set_ylim(-118, -86)
    limit_line(ax, x=5.95)
    ax.set_xticks(np.arange(6) + 0.5, [f"{k} off" for k in range(6)])
    ax.set_ylabel("dBm")
    save(pg, "C2_spaghetti")


def c3():
    pg = page("Every rank's power varies by trial, but the ranks are always taken in the "
              "same order", "Received power of each base station in 1,000 trials, dBm per "
              "megahertz; bar marks the median", "Strip plot of 1,000 draws for each of ranks "
              "1 to 6, overlapping heavily, with median markers.")
    ax, = axes(pg)
    rng = np.random.default_rng(0)
    for j in range(6):
        x = j + rng.uniform(-0.28, 0.28, len(P1))
        ax.scatter(x, P1[:, j], s=2, color=GRAY, alpha=0.35, lw=0)
        ax.plot([j - 0.33, j + 0.33], [INS[j]] * 2, color=BLUE, lw=2.2)
    ax.text(0.38, INS[0], "Median", color=BLUE, fontsize=8, fontweight="bold", va="center")
    ax.set_xticks(range(6), [f"Rank {r}" for r in RANKS])
    ax.set_ylabel("dBm")
    ax.annotate(f"Rank 2 is stronger than rank 1\nin {100 * np.mean(P1[:, 1] > P1[:, 0]):.0f}% of trials",
                (1, -90), (2.4, -86), fontsize=8, color=DARK,
                arrowprops=dict(arrowstyle="-", color=GRAY, lw=0.8))
    save(pg, "C3_strip_by_rank")


def c4():
    n = 12
    pg = page("Heat map of the first 12 trials: the cut is always a straight line from the left",
              "Received power by trial and rank, dBm per megahertz (darker is stronger); tiles "
              "left of the blue edge are off", "Heat map with 12 rows and 6 columns; a blue "
              "step edge marks the turned-off ranks in each row.", h=4.3)
    ax, = axes(pg, grid=None)
    im = ax.imshow(P1[:n], cmap=T.cmap(), aspect="auto", vmin=-115, vmax=-88)
    for i in range(n):
        c = SIZE[i]
        ax.plot([c - 0.5, c - 0.5], [i - 0.5, i + 0.5], color=BLUE, lw=2.5)
        ax.text(5.75, i, f"{c} off", va="center", fontsize=8, color=DARK)
    ax.set_xticks(range(6), [f"Rank {r}" for r in RANKS])
    ax.set_yticks(range(n), [f"Trial {i + 1}" for i in range(n)])
    ax.set_xlim(-0.5, 6.4)
    ax.spines["bottom"].set_visible(False)
    cb = pg.fig.colorbar(im, ax=ax, fraction=0.03, pad=0.08)
    cb.ax.tick_params(labelsize=8, length=0)
    cb.outline.set_visible(False)
    cb.ax.set_title("dBm", fontsize=8, loc="left")
    save(pg, "C4_heatmap_trials")


# ---------------------------------------------------------------- fixed vs free
def tile_grid(ax, masks, title_s):
    n = len(masks)
    for i, m in enumerate(masks):
        for j in range(6):
            ax.add_patch(Rectangle((j, n - 1 - i), 0.9, 0.82, color=DARK if m[j] else "#ECEDEE"))
    ax.set_xlim(-0.1, 6)
    ax.set_ylim(-0.3, n + 0.2)
    ax.set_xticks(np.arange(6) + 0.45, RANKS)
    ax.set_yticks([])
    ax.spines["bottom"].set_visible(False)
    title(ax, title_s)


def masks_fixed(idx):
    return [np.arange(6) < SIZE[i] for i in idx]


def masks_free(idx):
    out = []
    for i in idx:
        m = np.zeros(6, bool)
        m[ORDER_FREE[i, :SIZE_FREE[i]]] = True
        out.append(m)
    return out


def d1():
    n = 50
    idx = np.argsort(SIZE[:n], kind="stable")
    pg = page("Every trial turns off the top of the same list; free choice scatters",
              "First 50 trials, sorted by number off. Dark tile = turned off. Columns are "
              "median ranks", "Two tile grids: fixed order fills each row from the left with "
              "no gaps; free choice has scattered tiles.", h=5.2)
    a, b = axes(pg, 1, 2, grid=None, wspace=0.25)
    tile_grid(a, masks_fixed(idx), "Fixed median order (the method)")
    idx2 = np.argsort(SIZE_FREE[:n], kind="stable")
    tile_grid(b, masks_free(idx2), "If each trial chose its own")
    a.set_xlabel("Rank", fontsize=8)
    b.set_xlabel("Rank", fontsize=8)
    save(pg, "D1_tile_grids")


def d2():
    fixed = np.array([np.mean(SIZE > j) for j in range(6)]) * 100
    m = np.array(masks_free(range(len(P1))))
    free = m.mean(0) * 100
    pg = page(f"The fixed order turns off rank 1 in {fixed[0]:.1f}% of trials; free choice, "
              f"{free[0]:.0f}%",
              "Share of 1,000 trials in which each base station is turned off",
              "Paired bar chart by rank: fixed order falls steadily from rank 1 to 6; free "
              "choice is flatter.")
    ax, = axes(pg)
    x = np.arange(6)
    ax.bar(x - 0.19, fixed, 0.36, color=BLUE)
    ax.bar(x + 0.19, free, 0.36, color=LIGHT)
    for xi, f, g in zip(x, fixed, free):
        ax.text(xi - 0.19, f + 1.5, f"{f:.0f}", ha="center", fontsize=8, color=BLUE,
                fontweight="bold")
        ax.text(xi + 0.19, g + 1.5, f"{g:.0f}", ha="center", fontsize=8, color=DARK)
    ax.text(4.6, 70, "Blue: fixed order\nGray: free choice", fontsize=8, color=DARK)
    ax.set_xticks(x, [f"Rank {r}" for r in RANKS])
    ax.set_ylim(0, 110)
    ax.set_ylabel("% of trials off")
    save(pg, "D2_off_rate_by_rank")


def d3():
    m = np.array(masks_free(range(len(P1))))
    keys = ["".join("X" if v else "." for v in row) for row in m]
    uniq, cnt = np.unique(keys, return_counts=True)
    o = np.argsort(-cnt)
    n_fixed = len(np.unique(SIZE))
    pg = page(f"Free choice produces {len(uniq)} different lists; the fixed order "
              f"produces {n_fixed}",
              "Number of trials (of 1,000) using each distinct set of turned-off base stations; "
              "top 15 free-choice sets shown", "Bar chart of the 15 most common free-choice "
              "sets, each labeled with its pattern of ranks.", h=4.3)
    ax, = axes(pg, grid="x")
    top = o[:15]
    labels = []
    for k in uniq[top]:
        r = [RANKS[i] for i, ch in enumerate(k) if ch == "X"]
        labels.append("Ranks " + ", ".join(r) if r else "None")
    is_prefix = [k == "X" * k.count("X") + "." * (6 - k.count("X")) for k in uniq[top]]
    ax.barh(range(15), cnt[top], color=[BLUE if p else LIGHT for p in is_prefix], height=0.7)
    for i, c in enumerate(cnt[top]):
        ax.text(c + 3, i, str(c), va="center", fontsize=8)
    ax.set_yticks(range(15), labels, fontsize=8)
    ax.invert_yaxis()
    ax.set_xlabel("trials")
    ax.text(0.98, 0.05, "Blue: also a fixed-order list", transform=ax.transAxes, ha="right",
            fontsize=8, color=BLUE, fontweight="bold")
    save(pg, "D3_distinct_lists")


# ---------------------------------------------------------------- list size
def e1():
    counts = DIST * 10
    dots = np.floor(counts / 10).astype(int)
    rem = counts / 10 - dots
    dots[np.argsort(-rem)[:100 - dots.sum()]] += 1
    pg = page(f"Count 80 dots from the left: the 80th lands at {Q}; plus one, the list is "
              f"{LIST}", "Quantile dot plot: each dot is 10 of the 1,000 trials (largest-"
              "remainder rounding)", "Quantile dot plot by number of stations off; the first "
              "80 dots are blue and the 80th falls in the stack at 4.", h=4.6)
    ax, = axes(pg, grid=None)
    ax.set_aspect("equal")
    seen = 0
    sp, d = 1.7, 0.42
    for k in range(7):
        for j in range(dots[k]):
            seen += 1
            ax.add_patch(Circle((k * sp + (j % 3 - 1) * d, (j // 3) * d + 0.3), 0.17,
                                color=BLUE if seen <= 80 else "#B0B2B5"))
        ax.text(k * sp, -0.05, str(k), ha="center", va="top", fontsize=9)
        if dots[k]:
            ax.text(k * sp, (np.ceil(dots[k] / 3)) * d + 0.35, f"{dots[k]}", ha="center",
                    fontsize=8, color=DARK)
    ax.text(3 * sp, -1.05, "Base stations turned off (dot counts above each stack)",
            ha="center", fontsize=8.5)
    top = 13 * d + 0.9
    ax.annotate("", (LIST * sp, top), (Q * sp, top),
                arrowprops=dict(arrowstyle="->", color=DARK, lw=1))
    ax.text((Q + LIST) / 2 * sp, top + 0.15, "+1 margin", ha="center", fontsize=8, color=DARK)
    ax.text(-0.8, top + 0.15, f"80 blue dots; the 80th sits at {Q}", fontsize=8.5, color=BLUE,
            fontweight="bold")
    ax.set_xlim(-0.9, 6 * sp + 0.9)
    ax.set_ylim(-1.5, top + 0.7)
    ax.axis("off")
    save(pg, "E1_quantile_dots")


def e2():
    pg = page(f"The 80th percentile of the 1,000 cut points is {Q}; the list is {LIST}",
              "Share of trials by number of base stations turned off, fixed median order",
              "Bar chart of the cut-point distribution, bars 0 to 4 blue, 5 and 6 gray.")
    ax, = axes(pg)
    k = np.arange(7)
    ax.bar(k, DIST, color=[BLUE if i <= Q else LIGHT for i in k], width=0.65)
    for i, v in zip(k, DIST):
        ax.text(i, v + 0.8, f"{v:.1f}%", ha="center", fontsize=8)
    ax.text(1.0, 31, f"{DIST[:Q + 1].sum():.1f}% of trials\nneed {Q} or fewer", color=BLUE,
            fontsize=8.5, fontweight="bold", ha="center")
    ax.set_xticks(k, [str(i) for i in k])
    ax.set_xlabel("Base stations turned off")
    ax.set_ylim(0, 42)
    ax.set_ylabel("% of trials")
    save(pg, "E2_histogram")


def e3():
    pg = page(f"Read the list size off the curve: 80% of trials at {Q}, plus one is {LIST}",
              "Cumulative share of trials needing at most this many base stations off",
              "Cumulative step curve crossing 80% at 4 stations; arrow to 5 for the margin.")
    ax, = axes(pg)
    k = np.arange(7)
    c = np.cumsum(DIST)
    ax.step(np.r_[-0.5, k + 0.5], np.r_[0, c], where="post", color=GRAY, lw=1.6)
    ax.axhline(80, color=BLUE, lw=1, ls=(0, (3, 2)))
    ax.plot([Q + 0.5], [c[Q]], "o", color=BLUE)
    ax.annotate(f"{c[Q]:.1f}% need {Q} or fewer", (Q + 0.5, c[Q]), (1.2, 92), fontsize=8.5,
                color=BLUE, fontweight="bold", arrowprops=dict(arrowstyle="-", color=BLUE))
    ax.text(-0.4, 81.5, "80%", color=DARK, fontsize=8)
    ax.set_xticks(k)
    ax.set_xlabel("Base stations turned off (at most)")
    ax.set_ylabel("% of trials")
    ax.set_ylim(0, 105)
    ax.set_xlim(-0.6, 6.6)
    save(pg, "E3_cumulative")


def e4():
    n = np.arange(1, len(SIZE) + 1)
    run = np.array([np.ceil(np.percentile(SIZE[:i], PCT, method="hazen")) for i in n])
    pg = page(f"The list size settles at {Q} after about "
              f"{int(n[np.where(run != Q)[0].max()] + 1)} trials",
              "Running 80th percentile of the cut points, rounded up, as trials accumulate",
              "Line chart of the running 80th percentile versus number of trials, settling at 4.")
    ax, = axes(pg)
    ax.plot(n, run, color=BLUE, lw=1.6, drawstyle="steps-post")
    ax.set_xscale("log")
    ax.set_xlabel("Trials so far (log scale)")
    ax.set_ylabel("80th percentile")
    ax.set_yticks(range(0, 7))
    ax.set_ylim(0, 6.5)
    save(pg, "E4_running_percentile")


# ---------------------------------------------------------------- validation
def f1():
    pg = page(f"With {LIST} off, the total meets the limit in {PASS:.0f}% of trials: "
              "the radius passes",
              "Share of 1,000 validation trials in which the aggregate exceeds each level, "
              "dBm per megahertz", "Exceedance curve of the validation aggregate; at the "
              "−99 dBm limit, 10.7% of trials exceed.")
    ax, = axes(pg, grid="both")
    s = np.sort(AGG)
    ex = 100 * (1 - np.arange(1, len(s) + 1) / len(s))
    ax.plot(s, ex, color=BLUE, lw=1.8)
    ax.axvline(LIM, color=PURPLE, lw=1.2, ls=(0, (4, 2)))
    ax.text(LIM + 0.2, 60, "Limit\n−99 dBm", color=PURPLE, fontsize=8, fontweight="bold")
    ax.axhline(20, color=GRAY, lw=0.9, ls=(0, (2, 2)))
    ax.text(s[0], 21.5, "20% allowed", color=DARK, fontsize=8)
    ax.plot(Q_AGG, 20, "o", color=BLUE)
    ax.annotate(f"80th percentile {Q_AGG:.1f} dBm,\n{LIM - Q_AGG:.1f} dB under the limit",
                (Q_AGG, 20), (Q_AGG - 9, 45), fontsize=8, color=BLUE, fontweight="bold",
                arrowprops=dict(arrowstyle="-", color=BLUE))
    ax.set_xlabel("Aggregate, dBm")
    ax.set_ylabel("% of trials exceeding")
    ax.set_ylim(0, 100)
    save(pg, "F1_exceedance")


def f2():
    pg = page(f"Check run: the 80th percentile is {Q_AGG:.1f} dBm, under the limit", "Validation aggregate in 1,000 trials, dBm per megahertz",
              "Histogram of the validation aggregate with the 80th percentile and limit marked.")
    ax, = axes(pg)
    bins = np.arange(np.floor(AGG.min()), np.ceil(AGG.max()) + 0.5, 0.5)
    ax.hist(AGG, bins, color=LIGHT)
    ax.hist(AGG[AGG > LIM], bins, color=PURPLE)
    ax.axvline(Q_AGG, color=BLUE, lw=1.4)
    ax.text(Q_AGG - 0.2, ax.get_ylim()[1] * 0.92, f"80th percentile\n{Q_AGG:.1f} dBm",
            color=BLUE, fontsize=8, fontweight="bold", ha="right")
    ax.text(LIM + 0.3, ax.get_ylim()[1] * 0.6, f"Over the limit:\n{100 - PASS:.1f}% of trials",
            color=PURPLE, fontsize=8, fontweight="bold")
    ax.set_xlabel("Aggregate, dBm")
    ax.set_ylabel("trials")
    save(pg, "F2_histogram")


def f3():
    shares = fw(np.r_[INS[LIST:], OUTS])
    shares = shares / shares.sum() * 100
    labels = [f"Rank {r}" for r in RANKS[LIST:]] + [f"Outside {o}" for o in OUT_LABELS]
    pg = page(f"In the check run, base stations outside the radius carry "
              f"{shares[1:].sum():.0f}% of the median power",
              "Who stays on with the list applied, and each one's share of the median "
              "aggregate, linear power", "Tile strip of 10 stations with 5 marked off, and "
              "bars of share for the 5 still on.", h=4.0)
    a, b = axes(pg, 2, 1, grid=None, hr=[0.8, 2.2], hspace=0.9)
    a.axis("off")
    names = RANKS + OUT_LABELS
    for j, nme in enumerate(names):
        off = j < LIST
        a.add_patch(Rectangle((j + (0.6 if j >= 6 else 0), 0), 0.85, 0.85,
                              color="#ECEDEE" if off else (BLUE if j < 6 else GRAY)))
        a.text(j + (0.6 if j >= 6 else 0) + 0.42, 0.42, nme, ha="center", va="center",
               fontsize=8, color=DARK if off else "white", fontweight="bold")
    a.text(0, 1.15, "Turned off (on the list)", fontsize=8, color=DARK)
    a.text(6.6, 1.15, "Outside the radius: always on", fontsize=8, color=DARK)
    a.set_xlim(-0.1, 10.8)
    a.set_ylim(-0.1, 1.6)
    style(b, "x")
    b.barh(range(5), shares, color=[BLUE] + [GRAY] * 4, height=0.6)
    for i, s in enumerate(shares):
        b.text(s + 1, i, f"{s:.0f}%", va="center", fontsize=8)
    b.set_yticks(range(5), labels)
    b.invert_yaxis()
    b.set_xlim(0, 70)
    b.set_xlabel("% of median aggregate in the check run")
    save(pg, "F3_who_stays_on")


def f4():
    pg = page(f"Turning off {LIST} moves the 80th percentile from "
              f"{np.percentile(AGG_ALL, PCT, method='hazen'):.1f} to {Q_AGG:.1f} dBm",
              "Share of 1,000 trials exceeding each level, dBm per megahertz: all ten on, "
              "versus the list applied", "Two exceedance curves: all on (gray, right) and list "
              "applied (blue, left), with the limit between them.")
    ax, = axes(pg, grid="both")
    for data, col, lab, xoff in [(AGG_ALL, DARK, "All ten on", 0.3), (AGG, BLUE,
                                                                       f"{LIST} off", -0.3)]:
        s = np.sort(data)
        ex = 100 * (1 - np.arange(1, len(s) + 1) / len(s))
        ax.plot(s, ex, color=col, lw=1.8)
        q = np.percentile(data, PCT, method="hazen")
        ax.text(q + xoff * 6, 30, lab, color=col, fontsize=8.5, fontweight="bold",
                ha="left" if xoff > 0 else "right")
    ax.axvline(LIM, color=PURPLE, lw=1.2, ls=(0, (4, 2)))
    ax.text(LIM + 0.2, 85, "Limit", color=PURPLE, fontsize=8, fontweight="bold")
    ax.axhline(20, color=GRAY, lw=0.9, ls=(0, (2, 2)))
    ax.set_xlabel("Aggregate, dBm")
    ax.set_ylabel("% of trials exceeding")
    ax.set_ylim(0, 100)
    save(pg, "F4_before_after")


def f5():
    pg = page(f"Each dot is one check-run trial: {PASS:.0f}% fall under the limit",
              "Validation aggregate, dBm per megahertz, 1,000 trials; purple dots exceed the "
              "limit", "Beeswarm-style strip of 1,000 trials with the 107 over the limit in "
              "purple.", h=3.4)
    ax, = axes(pg, grid="x")
    rng = np.random.default_rng(1)
    y = rng.uniform(-1, 1, len(AGG))
    over = AGG > LIM
    ax.scatter(AGG[~over], y[~over], s=5, color=GRAY, alpha=0.6, lw=0)
    ax.scatter(AGG[over], y[over], s=7, color=PURPLE, lw=0)
    ax.axvline(LIM, color=PURPLE, lw=1.2, ls=(0, (4, 2)))
    ax.text(LIM + 0.2, 1.15, f"Over: {over.sum()} trials", color=PURPLE, fontsize=8,
            fontweight="bold")
    ax.text(LIM - 0.3, 1.15, f"Under: {(~over).sum()} trials", color=DARK, fontsize=8,
            fontweight="bold", ha="right")
    ax.set_yticks([])
    ax.set_ylim(-1.3, 1.5)
    ax.set_xlabel("Aggregate, dBm")
    save(pg, "F5_trial_strip")


# ---------------------------------------------------------------- cost of fixed order
def g1():
    pg = page("One list for every trial costs about one more base station than a list "
              "for each", "Share of 1,000 trials by number turned off: fixed median order "
              "(up) versus free choice (down)", "Back-to-back bar chart; fixed order centers "
              "on 3 to 4, free choice on 2 to 3.")
    ax, = axes(pg)
    k = np.arange(7)
    ax.bar(k, DIST, color=BLUE, width=0.6)
    ax.bar(k, -DIST_FREE, color=LIGHT, width=0.6)
    ax.axhline(0, color=GRAY, lw=0.8)
    ax.text(6.4, 30, f"Fixed order\nmean {SIZE.mean():.2f}", color=BLUE, fontsize=8.5,
            fontweight="bold", ha="right")
    ax.text(6.4, -35, f"Free choice\nmean {SIZE_FREE.mean():.2f}", color=DARK, fontsize=8.5,
            fontweight="bold", ha="right")
    ax.set_yticks([-40, -20, 0, 20, 40], ["40%", "20%", "0", "20%", "40%"])
    ax.set_xticks(k)
    ax.set_xlabel("Base stations turned off")
    save(pg, "G1_back_to_back")


def g2():
    extra = SIZE - SIZE_FREE
    v = np.bincount(extra) / 10
    pg = page(f"In {v[0]:.0f}% of trials the fixed order costs nothing extra",
              "Extra base stations the fixed order turns off, compared with each trial's "
              "own best list", "Bar chart: 0 extra in most trials, 1 or 2 extra in the rest.")
    ax, = axes(pg)
    ax.bar(range(len(v)), v, color=[BLUE] + [GRAY] * (len(v) - 1), width=0.6)
    for i, x in enumerate(v):
        ax.text(i, x + 1, f"{x:.1f}%", ha="center", fontsize=8)
    ax.set_xticks(range(len(v)), [f"{i} extra" for i in range(len(v))])
    ax.set_ylabel("% of trials")
    ax.set_ylim(0, max(v) + 10)
    save(pg, "G2_extra_cost")


# ---------------------------------------------------------------- summary page
def h1():
    pg = page("The turn-off list in four steps", "Illustrative example: 6 base stations "
              "inside the radius, 4 outside, limit −99 dBm, 1,000 trials",
              "Four small panels left to right: ranking, one staircase, quantile dots, "
              "exceedance curve.", h=3.3)
    axs = axes(pg, 1, 4, wspace=0.45)
    a, b, c, d = axs
    title(a, "1. Rank once")
    a.barh(range(6), INS + 120, left=-120, color=BLUE, height=0.6)
    a.set_yticks(range(6), RANKS)
    a.invert_yaxis()
    a.set_xlim(-120, -95)
    a.set_xticks([-115, -100])
    title(b, "2. Cut each trial")
    stair(b, INS, label_cut=False)
    b.axhline(LIM, color=PURPLE, lw=1, ls=(0, (4, 2)))
    b.set_xlim(0, 6)
    b.set_xticks([0.5, 3.5], ["0", "3 off"])
    title(c, f"3. 80th pct: {Q}, +1 = {LIST}")
    k = np.arange(7)
    c.bar(k, DIST, color=[BLUE if i <= Q else LIGHT for i in k], width=0.7)
    c.set_xticks([0, 4, 6])
    title(d, f"4. Check: {PASS:.0f}% pass")
    s = np.sort(AGG)
    d.plot(s, 100 * (1 - np.arange(1, len(s) + 1) / len(s)), color=BLUE)
    d.axvline(LIM, color=PURPLE, lw=1, ls=(0, (4, 2)))
    d.set_xticks([-105, -99])
    for ax in axs:
        ax.tick_params(labelsize=8)
    save(pg, "H1_summary_strip")


FIGS = [a1, a2, a3, a4, b1, b2, b3, b4, c1, c2, c3, c4, d1, d2, d3, e1, e2, e3, e4,
        f1, f2, f3, f4, f5, g1, g2, h1]

if __name__ == "__main__":
    for f in FIGS:
        f()
    stats = dict(q=Q, list=LIST, q_agg=round(float(Q_AGG), 2), pass_pct=PASS,
                 rank2_over_rank1=round(100 * float(np.mean(P1[:, 1] > P1[:, 0])), 1))
    print(stats)
