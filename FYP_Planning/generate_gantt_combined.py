import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np
import os

# ── colour palette (matching reference image) ──────────────────────────
FYP1_COLOR   = '#4472C4'   # Blue
FYP2_COLOR   = '#00B050'   # Green (brighter green to match reference)
BOTH_COLOR   = '#FFFF00'   # Yellow (FYP 1 & 2)
HEADER_BG    = '#C0C0C0'   # Header row background (grey)
DARK_BG      = '#A6A6A6'   # Dark grey for report row

# ── task definitions ───────────────────────────────────────────────────
# Each task: (row_label, [(start_week, end_week, color), ...])
# Columns  1-15 representing 15 weeks
# Numbering will be purely manual row index

tasks = [
    ("Meeting with SV",                       [(1, 15, BOTH_COLOR)]),
    ("FYP Talk",                              [(1, 2, FYP1_COLOR)]),
    ("Select Coral Health Title",             [(2, 4, FYP1_COLOR)]),
    ("Project Title Confirmation",            [(4, 5, FYP1_COLOR)]),
    ("Literature Review (Coral Diseases)",    [(3, 7, FYP1_COLOR)]),

    # --- Methodology block (sub-items) ---
    ("Methodology",                           []),  # Section header
    ("  - Define EfficientNet & Grad-CAM",    [(5, 7, FYP1_COLOR)]),
    ("  - Phase 1: Foundation",               [(1, 2, FYP2_COLOR)]),
    ("  - Data Pipeline",                     [(3, 3, FYP2_COLOR)]),
    ("  - EfficientNetB0 Training",           [(4, 4, FYP2_COLOR)]),
    ("  - SWA Ensemble & Opt.",               [(6, 7, FYP2_COLOR)]),
    ("  - Evaluation & Grad-CAM",             [(8, 9, FYP2_COLOR)]),
    ("  - Web Application Dev.",              [(10, 12, FYP2_COLOR)]),

    # --- Report block ---
    ("Report :",                              []),  # Section header
    ("  Chapter 1",                           [(8, 10, FYP1_COLOR), (12, 14, FYP2_COLOR)]),
    ("  Chapter 2",                           [(8, 11, FYP1_COLOR), (12, 14, FYP2_COLOR)]),
    ("  Chapter 3",                           [(9, 11, FYP1_COLOR), (12, 12, BOTH_COLOR), (13, 14, FYP2_COLOR)]),
    ("  Chapter 4",                           [(12, 14, FYP2_COLOR)]),
    ("  Chapter 5",                           [(13, 15, FYP2_COLOR)]),

    # --- Milestones ---
    ("Progress Report 1",                     [(8, 9, BOTH_COLOR)]), # Yellow for both
    ("Progress Report 2",                     [(12, 13, BOTH_COLOR)]), # Yellow for both
    ("FYP Viva Presentation",                 [(14, 15, BOTH_COLOR)]),
    ("Final Report Submission",               [(15, 15, BOTH_COLOR)]),
]

TOTAL_COLS = 15

def draw_gantt():
    num_rows = len(tasks)
    fig_width = 16
    fig_height = 0.38 * num_rows + 2.0
    fig, ax = plt.subplots(figsize=(fig_width, fig_height), facecolor='white')

    cell_w = 1.0
    cell_h = 0.6
    label_width = 5.5
    table_left = label_width

    # ── Title ──
    ax.text(table_left + TOTAL_COLS * cell_w / 2, num_rows * cell_h + 2.2,
            "GANTT CHART", ha='center', va='center',
            fontsize=16, fontweight='bold', fontfamily='serif')

    # ── Legend on top ──
    # [ FYP 1 ] [ Blue ]   [ FYP 2 ] [ Green ]   [ FYP 1 & 2 ] [ Yellow ]
    legend_y = num_rows * cell_h + 1.2
    
    # FYP 1
    ax.add_patch(plt.Rectangle((table_left + 1, legend_y), 1.5, cell_h, facecolor='white', edgecolor='black', linewidth=0.5))
    ax.text(table_left + 1 + 0.75, legend_y + cell_h / 2, "FYP 1", ha='center', va='center', fontsize=9, fontweight='bold')
    ax.add_patch(plt.Rectangle((table_left + 2.5, legend_y), 1.5, cell_h, facecolor=FYP1_COLOR, edgecolor='black', linewidth=0.5))

    # FYP 2
    ax.add_patch(plt.Rectangle((table_left + 5.5, legend_y), 1.5, cell_h, facecolor='white', edgecolor='black', linewidth=0.5))
    ax.text(table_left + 5.5 + 0.75, legend_y + cell_h / 2, "FYP 2", ha='center', va='center', fontsize=9, fontweight='bold')
    ax.add_patch(plt.Rectangle((table_left + 7.0, legend_y), 1.5, cell_h, facecolor=FYP2_COLOR, edgecolor='black', linewidth=0.5))

    # FYP 1 & 2
    ax.add_patch(plt.Rectangle((table_left + 10, legend_y), 1.5, cell_h, facecolor='white', edgecolor='black', linewidth=0.5))
    ax.text(table_left + 10 + 0.75, legend_y + cell_h / 2, "FYP 1 & 2", ha='center', va='center', fontsize=9, fontweight='bold')
    ax.add_patch(plt.Rectangle((table_left + 11.5, legend_y), 1.5, cell_h, facecolor=BOTH_COLOR, edgecolor='black', linewidth=0.5))


    # ── Column headers (week numbers) ──
    header_y = num_rows * cell_h + 0.5
    ax.add_patch(plt.Rectangle((0, header_y), 1.0, cell_h,
                                facecolor=HEADER_BG, edgecolor='black', linewidth=0.5))
    ax.text(0.5, header_y + cell_h / 2, "No", ha='center', va='center', fontsize=7, fontweight='bold')

    ax.add_patch(plt.Rectangle((1.0, header_y), label_width - 1.0, cell_h,
                                facecolor=HEADER_BG, edgecolor='black', linewidth=0.5))
    ax.text(1.0 + (label_width - 1.0) / 2, header_y + cell_h / 2,
            "Task / Week", ha='left', va='center', fontsize=7, fontweight='bold')

    for col in range(TOTAL_COLS):
        x = table_left + col * cell_w
        week_num = col + 1
        ax.add_patch(plt.Rectangle((x, header_y), cell_w, cell_h,
                                    facecolor=HEADER_BG, edgecolor='black', linewidth=0.5))
        ax.text(x + cell_w / 2, header_y + cell_h / 2,
                str(week_num), ha='center', va='center', fontsize=7, fontweight='bold')

    # ── Draw task rows ──
    row_num = 0
    for idx, (label, spans) in enumerate(tasks):
        y = (num_rows - 1 - idx) * cell_h
        is_report_row = label == "Report :"
        is_method_row = label == "Methodology"
        is_section = is_report_row or is_method_row
        is_sub = label.startswith("  -") or label.startswith("  Chapter")

        bg_color = DARK_BG if is_report_row else 'white'

        # Row number cell
        ax.add_patch(plt.Rectangle((0, y), 1.0, cell_h,
                                    facecolor=bg_color, edgecolor='black', linewidth=0.3))
        
        if not is_section and not is_sub:
            row_num += 1
            ax.text(0.5, y + cell_h / 2, str(row_num), ha='center', va='center', fontsize=7)

        # Task label cell
        ax.add_patch(plt.Rectangle((1.0, y), label_width - 1.0, cell_h,
                                    facecolor=bg_color, edgecolor='black', linewidth=0.3))
        
        display_label = label.strip() if is_section else label
        ax.text(1.2, y + cell_h / 2, display_label, ha='left', va='center', fontsize=7,
                fontweight='bold' if is_section else 'normal')

        # Grid cells for weeks
        for col in range(TOTAL_COLS):
            x = table_left + col * cell_w
            # the reference image colors the entire Report: row dark grey
            fill_color = DARK_BG if is_report_row else 'white'
            ax.add_patch(plt.Rectangle((x, y), cell_w, cell_h,
                                        facecolor=fill_color, edgecolor='#A0A0A0', linewidth=0.3))

        # Colored bars
        for (start, end, color) in spans:
            bar_x = table_left + (start - 1) * cell_w
            bar_w = (end - start + 1) * cell_w
            
            # The reference image has bars occupying the FULL cell height and width exactly
            ax.add_patch(plt.Rectangle((bar_x, y), bar_w, cell_h,
                                        facecolor=color, edgecolor='black', linewidth=0.5,
                                        alpha=1.0))

    # ── Axis settings ──
    ax.set_xlim(0, table_left + TOTAL_COLS * cell_w)
    ax.set_ylim(-0.5, num_rows * cell_h + 3)
    ax.set_aspect('equal')
    ax.axis('off')

    plt.tight_layout()
    output_dir = os.path.dirname(os.path.abspath(__file__))
    output_path = os.path.join(output_dir, "gantt_chart_combined.png")
    plt.savefig(output_path, dpi=300, bbox_inches='tight', facecolor='white')
    plt.close()
    print(f"[OK] Generated gantt_chart_combined.png")

if __name__ == "__main__":
    draw_gantt()
