#!/usr/bin/env python3
"""Build docs/working_paper.docx from docs/working_paper.md.

The Markdown file is the source. This script converts it with pandoc, using a
reference document it styles on the fly (US Letter, 1-inch margins, Arial,
DRAFT//PRE-DECISIONAL header and footer, page numbers), then formats the
tables with python-docx.

Run from anywhere:

    python3 docs/build/build_working_paper_docx.py

Needs: pandoc (3.x) and python-docx.
"""

import re
import subprocess
import sys
import tempfile
from pathlib import Path

from docx import Document
from docx.enum.section import WD_ORIENT
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor
from docx.text.paragraph import Paragraph

REPO_URL = "https://github.com/nicklasorte/aggregate_explainer/blob/main"
MARKING = "DRAFT//PRE-DECISIONAL"
FONT = "Arial"
HEADING_COLOR = RGBColor(0x1F, 0x38, 0x64)
HEADER_FILL = "D9E2F3"
BORDER_COLOR = "8EAADB"

DOCS = Path(__file__).resolve().parents[1]
SOURCE = DOCS / "working_paper.md"
OUTPUT = DOCS / "working_paper.docx"


def preprocess(markdown: str) -> str:
    """Make the GitHub-oriented Markdown suitable for a standalone document."""
    # Relative links to other repository files become GitHub links.
    markdown = re.sub(
        r"\]\((?!https?://|#|figures/)([^)]+\.md)\)",
        lambda m: f"]({REPO_URL}/docs/{m.group(1)})",
        markdown,
    )
    return markdown


def set_run_font(style, size_pt, bold=None, color=None, italic=None):
    font = style.font
    font.name = FONT
    font.size = Pt(size_pt)
    if bold is not None:
        font.bold = bold
    if italic is not None:
        font.italic = italic
    if color is not None:
        font.color.rgb = color
    # East Asian and complex-script font slots, so Word doesn't substitute.
    rpr = style.element.get_or_add_rPr()
    rfonts = rpr.find(qn("w:rFonts"))
    if rfonts is None:
        rfonts = OxmlElement("w:rFonts")
        rpr.insert(0, rfonts)
    for attr in ("w:ascii", "w:hAnsi", "w:eastAsia", "w:cs"):
        rfonts.set(qn(attr), FONT)
    for attr in ("w:asciiTheme", "w:hAnsiTheme", "w:eastAsiaTheme", "w:cstheme"):
        if rfonts.get(qn(attr)) is not None:
            del rfonts.attrib[qn(attr)]


def add_page_number(paragraph):
    """Append a PAGE field to a paragraph."""
    run = paragraph.add_run()
    for kind, text in (("begin", None), (None, "PAGE"), ("end", None)):
        if kind:
            fld = OxmlElement("w:fldChar")
            fld.set(qn("w:fldCharType"), kind)
            run._r.append(fld)
        else:
            instr = OxmlElement("w:instrText")
            instr.set(qn("xml:space"), "preserve")
            instr.text = text
            run._r.append(instr)


def build_reference(path: Path) -> None:
    """Write a styled pandoc reference document to path."""
    subprocess.run(
        ["pandoc", "-o", str(path), "--print-default-data-file", "reference.docx"],
        check=True,
    )

    doc = Document(str(path))
    styles = doc.styles

    for name in ("Normal", "Body Text", "First Paragraph", "Compact"):
        if name in styles:
            set_run_font(styles[name], 11)
    if "Body Text" in styles:
        fmt = styles["Body Text"].paragraph_format
        fmt.space_before = Pt(0)
        fmt.space_after = Pt(8)
        fmt.line_spacing = 1.1
    for name, size in (("Title", 20), ("Heading 1", 15), ("Heading 2", 12.5), ("Heading 3", 11.5)):
        if name in styles:
            set_run_font(styles[name], size, bold=True, color=HEADING_COLOR)
            fmt = styles[name].paragraph_format
            fmt.space_before = Pt(18 if name != "Title" else 0)
            fmt.space_after = Pt(6)
            fmt.keep_with_next = True
    if "Block Text" in styles:
        set_run_font(styles["Block Text"], 11, italic=False)
    if "Hyperlink" in styles:
        styles["Hyperlink"].font.name = FONT

    section = doc.sections[0]
    section.orientation = WD_ORIENT.PORTRAIT
    section.page_width = Inches(8.5)
    section.page_height = Inches(11)
    for side in ("left_margin", "right_margin", "top_margin", "bottom_margin"):
        setattr(section, side, Inches(1))
    section.header_distance = Inches(0.5)
    section.footer_distance = Inches(0.5)
    section.gutter = Inches(0)

    header = section.header.paragraphs[0]
    header.text = MARKING
    header.alignment = WD_ALIGN_PARAGRAPH.CENTER
    header.runs[0].font.bold = True
    header.runs[0].font.size = Pt(9)
    header.runs[0].font.name = FONT

    footer = section.footer.paragraphs[0]
    footer.text = f"{MARKING}    |    Page "
    footer.alignment = WD_ALIGN_PARAGRAPH.CENTER
    footer.runs[0].font.size = Pt(9)
    footer.runs[0].font.name = FONT
    add_page_number(footer)
    footer.runs[-1].font.size = Pt(9)
    footer.runs[-1].font.name = FONT

    doc.save(str(path))


def insert_before_any(parent, element, successors) -> None:
    """Insert element before the first child named in successors (schema order)."""
    for name in successors:
        found = parent.find(qn(f"w:{name}"))
        if found is not None:
            found.addprevious(element)
            return
    parent.append(element)


def set_cell_shading(cell, fill: str) -> None:
    tcpr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), fill)
    tcpr.append(shd)


def set_table_borders(table) -> None:
    tblpr = table._tbl.tblPr
    borders = OxmlElement("w:tblBorders")
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        el = OxmlElement(f"w:{edge}")
        el.set(qn("w:val"), "single")
        el.set(qn("w:sz"), "4")
        el.set(qn("w:space"), "0")
        el.set(qn("w:color"), BORDER_COLOR)
        borders.append(el)
    existing = tblpr.find(qn("w:tblBorders"))
    if existing is not None:
        tblpr.remove(existing)
    insert_before_any(tblpr, borders,
                      ("shd", "tblLayout", "tblCellMar", "tblLook", "tblCaption", "tblDescription"))


TEXT_WIDTH_DXA = 9360  # 6.5 in at 1440 per inch
MIN_COL_DXA = 1100


def cell_text_length(cell) -> int:
    """Characters in a cell, counting equation text (m:t) as well as w:t."""
    texts = cell._tc.xpath(".//w:t/text() | .//m:t/text()")
    return sum(len(t) for t in texts)


def set_column_widths(table) -> None:
    """Size columns by their longest cell so equations get the room."""
    n_cols = len(table.columns)
    longest = [1] * n_cols
    for row in table.rows:
        for c, cell in enumerate(row.cells[:n_cols]):
            longest[c] = max(longest[c], min(cell_text_length(cell), 90))
    total = sum(longest)
    widths = [max(MIN_COL_DXA, round(TEXT_WIDTH_DXA * w / total)) for w in longest]
    scale = TEXT_WIDTH_DXA / sum(widths)
    widths = [round(w * scale) for w in widths]

    tblpr = table._tbl.tblPr
    tblw = tblpr.find(qn("w:tblW"))
    if tblw is None:
        tblw = OxmlElement("w:tblW")
        insert_before_any(tblpr, tblw,
                          ("jc", "tblCellSpacing", "tblInd", "tblBorders", "shd", "tblLayout",
                           "tblCellMar", "tblLook", "tblCaption", "tblDescription"))
    tblw.set(qn("w:type"), "dxa")
    tblw.set(qn("w:w"), str(sum(widths)))
    layout = tblpr.find(qn("w:tblLayout"))
    if layout is None:
        layout = OxmlElement("w:tblLayout")
        insert_before_any(tblpr, layout, ("tblCellMar", "tblLook", "tblCaption", "tblDescription"))
    layout.set(qn("w:type"), "fixed")

    grid = table._tbl.tblGrid
    for gc, w in zip(grid.findall(qn("w:gridCol")), widths):
        gc.set(qn("w:w"), str(w))
    for row in table.rows:
        for cell, w in zip(row.cells, widths):
            tcpr = cell._tc.get_or_add_tcPr()
            tcw = tcpr.find(qn("w:tcW"))
            if tcw is None:
                tcw = OxmlElement("w:tcW")
                tcpr.insert(0, tcw)
            tcw.set(qn("w:type"), "dxa")
            tcw.set(qn("w:w"), str(w))


def format_tables(path: Path) -> None:
    doc = Document(str(path))
    for table in doc.tables:
        table.alignment = WD_TABLE_ALIGNMENT.CENTER
        set_table_borders(table)
        set_column_widths(table)
        for r, row in enumerate(table.rows):
            trpr = row._tr.get_or_add_trPr()
            if trpr.find(qn("w:cantSplit")) is None:
                trpr.append(OxmlElement("w:cantSplit"))
            for cell in row.cells:
                if r == 0:
                    set_cell_shading(cell, HEADER_FILL)
                for paragraph in cell.paragraphs:
                    # Keep each table on one page.
                    paragraph.paragraph_format.keep_with_next = r < len(table.rows) - 1
                    paragraph.paragraph_format.space_before = Pt(2)
                    paragraph.paragraph_format.space_after = Pt(2)
                    for run in paragraph.runs:
                        run.font.size = Pt(9.5)
                        if r == 0:
                            run.font.bold = True
        # Room between a table and the paragraph after it.
        following = table._tbl.getnext()
        if following is not None and following.tag == qn("w:p"):
            Paragraph(following, table._parent).paragraph_format.space_before = Pt(8)
    # A lead-in line ("Things to notice:") stays on the page with its list.
    for paragraph in doc.paragraphs:
        if paragraph.text.rstrip().endswith(":"):
            paragraph.paragraph_format.keep_with_next = True
    doc.save(str(path))


def main() -> int:
    markdown = preprocess(SOURCE.read_text(encoding="utf-8"))
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        reference = tmp / "reference.docx"
        build_reference(reference)
        md_file = tmp / "working_paper.md"
        md_file.write_text(markdown, encoding="utf-8")
        subprocess.run(
            [
                "pandoc",
                str(md_file),
                "--from=gfm+tex_math_dollars",
                "--to=docx",
                f"--reference-doc={reference}",
                f"--resource-path={DOCS}",
                "--shift-heading-level-by=-1",
                "--metadata=lang:en-US",
                "-o",
                str(OUTPUT),
            ],
            check=True,
        )
    format_tables(OUTPUT)
    print(f"Wrote {OUTPUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
