"""
Generate Ablation Study Figures (CPU-only)
==========================================
Reads ablation_results.json and generates clean, report-ready figures.
No GPU needed — re-run freely to tweak styling.

Outputs → 03_Model_Evaluation/Ablation_TTA_MultiSeed/
"""

import os
import sys
import io
import json

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches

# ============================================================
# Configuration
# ============================================================
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(SCRIPT_DIR, 'Ablation_TTA_MultiSeed')
RESULTS_PATH = os.path.join(DATA_DIR, 'ablation_results.json')

# Professional color palette
COLOR_NO_TTA = '#2c7fb8'   # Blue
COLOR_TTA = '#d95f02'      # Orange
COLOR_CORRECT = '#1b9e77'  # Teal
COLOR_WRONG = '#d62728'    # Red
COLOR_BASELINE = '#7570b3' # Purple
BAR_COLORS = ['#2c7fb8', '#d95f02', '#1b9e77', '#d62728',
              '#7570b3', '#e7298a', '#66a61e', '#e6ab02']

# Common style
plt.rcParams.update({
    'font.family': 'sans-serif',
    'font.size': 11,
    'axes.titlesize': 14,
    'axes.titleweight': 'bold',
    'axes.labelsize': 12,
    'figure.facecolor': 'white',
    'axes.facecolor': 'white',
    'axes.grid': True,
    'grid.alpha': 0.3,
    'grid.linestyle': '--',
})


def load_results():
    """Load ablation results JSON."""
    if not os.path.exists(RESULTS_PATH):
        print(f"❌ Results not found: {RESULTS_PATH}")
        print("   Run run_ablation_study.py first.")
        sys.exit(1)

    with open(RESULTS_PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)

    print(f"✅ Loaded {len(data['results'])} configurations from ablation_results.json")
    return data


def get_paired_data(results):
    """Extract paired (no-TTA, TTA) data by seed count."""
    seed_counts = [1, 2, 3, 5]
    no_tta_results = {r['num_seeds']: r for r in results if not r['tta']}
    tta_results = {r['num_seeds']: r for r in results if r['tta']}
    return seed_counts, no_tta_results, tta_results


# ============================================================
# Figure 1: Accuracy vs Seed Count
# ============================================================
def plot_accuracy_by_seeds(results):
    seed_counts, no_tta, tta = get_paired_data(results)

    fig, ax = plt.subplots(figsize=(8, 5))

    acc_no_tta = [no_tta[s]['accuracy'] for s in seed_counts]
    acc_tta = [tta[s]['accuracy'] for s in seed_counts]

    ax.plot(seed_counts, acc_no_tta, 'o-', color=COLOR_NO_TTA, linewidth=2.5,
            markersize=10, label='No TTA', zorder=5)
    ax.plot(seed_counts, acc_tta, 's--', color=COLOR_TTA, linewidth=2.5,
            markersize=10, label='With TTA', zorder=5)

    # Annotate values
    for i, s in enumerate(seed_counts):
        ax.annotate(f"{acc_no_tta[i]:.2f}%", (s, acc_no_tta[i]),
                    textcoords="offset points", xytext=(0, 12), ha='center',
                    fontsize=9, color=COLOR_NO_TTA, fontweight='bold')
        ax.annotate(f"{acc_tta[i]:.2f}%", (s, acc_tta[i]),
                    textcoords="offset points", xytext=(0, -16), ha='center',
                    fontsize=9, color=COLOR_TTA, fontweight='bold')

    ax.set_xlabel('Number of Ensemble Seeds')
    ax.set_ylabel('Test Accuracy (%)')
    ax.set_title('Test Accuracy vs Ensemble Size')
    ax.set_xticks(seed_counts)
    ax.legend(loc='lower right', frameon=True, fancybox=True, shadow=True)

    # Dynamic y-axis
    all_acc = acc_no_tta + acc_tta
    y_min = min(all_acc) - 1.5
    y_max = max(all_acc) + 1.5
    ax.set_ylim(max(y_min, 90), min(y_max, 100.5))

    plt.tight_layout()
    path = os.path.join(DATA_DIR, 'ablation_accuracy_by_seeds.png')
    plt.savefig(path, dpi=200, bbox_inches='tight')
    plt.close()
    print(f"   📊 Saved: {os.path.basename(path)}")


# ============================================================
# Figure 2: Macro F1 vs Seed Count
# ============================================================
def plot_f1_by_seeds(results):
    seed_counts, no_tta, tta = get_paired_data(results)

    fig, ax = plt.subplots(figsize=(8, 5))

    f1_no_tta = [no_tta[s]['macro_f1'] for s in seed_counts]
    f1_tta = [tta[s]['macro_f1'] for s in seed_counts]

    ax.plot(seed_counts, f1_no_tta, 'o-', color=COLOR_NO_TTA, linewidth=2.5,
            markersize=10, label='No TTA', zorder=5)
    ax.plot(seed_counts, f1_tta, 's--', color=COLOR_TTA, linewidth=2.5,
            markersize=10, label='With TTA', zorder=5)

    for i, s in enumerate(seed_counts):
        ax.annotate(f"{f1_no_tta[i]:.4f}", (s, f1_no_tta[i]),
                    textcoords="offset points", xytext=(0, 12), ha='center',
                    fontsize=9, color=COLOR_NO_TTA, fontweight='bold')
        ax.annotate(f"{f1_tta[i]:.4f}", (s, f1_tta[i]),
                    textcoords="offset points", xytext=(0, -16), ha='center',
                    fontsize=9, color=COLOR_TTA, fontweight='bold')

    ax.set_xlabel('Number of Ensemble Seeds')
    ax.set_ylabel('Macro F1-Score')
    ax.set_title('Macro F1-Score vs Ensemble Size')
    ax.set_xticks(seed_counts)
    ax.legend(loc='lower right', frameon=True, fancybox=True, shadow=True)

    all_f1 = f1_no_tta + f1_tta
    y_min = min(all_f1) - 0.02
    y_max = max(all_f1) + 0.02
    ax.set_ylim(max(y_min, 0.9), min(y_max, 1.005))

    plt.tight_layout()
    path = os.path.join(DATA_DIR, 'ablation_f1_by_seeds.png')
    plt.savefig(path, dpi=200, bbox_inches='tight')
    plt.close()
    print(f"   📊 Saved: {os.path.basename(path)}")


# ============================================================
# Figure 3: Error Count Bar Chart
# ============================================================
def plot_errors_by_config(results):
    fig, ax = plt.subplots(figsize=(10, 5))

    configs = [r['config'] for r in results]
    errors = [r['total_errors'] for r in results]
    colors = [BAR_COLORS[i % len(BAR_COLORS)] for i in range(len(results))]

    bars = ax.bar(configs, errors, color=colors, edgecolor='white', linewidth=0.8, width=0.6)

    # Annotate error counts
    for bar, err in zip(bars, errors):
        ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 0.15,
                str(err), ha='center', va='bottom', fontweight='bold', fontsize=11)

    # Add descriptions below
    for i, r in enumerate(results):
        tta_str = '+TTA' if r['tta'] else ''
        label = f"{r['num_seeds']}s{tta_str}"
        ax.text(i, -0.6, label, ha='center', va='top', fontsize=8, color='gray')

    ax.set_xlabel('Configuration', labelpad=15)
    ax.set_ylabel('Number of Errors')
    ax.set_title('Misclassification Count')
    ax.set_ylim(0, max(errors) + 2)

    plt.tight_layout()
    path = os.path.join(DATA_DIR, 'ablation_errors_by_seeds.png')
    plt.savefig(path, dpi=200, bbox_inches='tight')
    plt.close()
    print(f"   📊 Saved: {os.path.basename(path)}")


# ============================================================
# Figure 4: Confidence Gap (Correct vs Wrong)
# ============================================================
def plot_confidence_gap(results):
    fig, ax = plt.subplots(figsize=(10, 5))

    configs = [r['config'] for r in results]
    conf_correct = [r['mean_conf_correct'] for r in results]
    conf_wrong = [r['mean_conf_wrong'] for r in results]

    x = np.arange(len(configs))
    width = 0.35

    bars1 = ax.bar(x - width / 2, conf_correct, width, color=COLOR_CORRECT,
                   label='Correct Predictions', edgecolor='white')
    bars2 = ax.bar(x + width / 2, conf_wrong, width, color=COLOR_WRONG,
                   label='Wrong Predictions', edgecolor='white')

    # Annotate
    for bar, val in zip(bars1, conf_correct):
        ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 0.5,
                f"{val:.1f}", ha='center', va='bottom', fontsize=8, color=COLOR_CORRECT)
    for bar, val in zip(bars2, conf_wrong):
        if val > 0:
            ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 0.5,
                    f"{val:.1f}", ha='center', va='bottom', fontsize=8, color=COLOR_WRONG)

    ax.set_xlabel('Configuration')
    ax.set_ylabel('Mean Confidence (%)')
    ax.set_title('Prediction Confidence: Correct vs Wrong')
    ax.set_xticks(x)
    ax.set_xticklabels(configs)
    ax.legend(loc='lower right', frameon=True, fancybox=True, shadow=True)
    ax.set_ylim(0, 105)

    plt.tight_layout()
    path = os.path.join(DATA_DIR, 'ablation_confidence_gap.png')
    plt.savefig(path, dpi=200, bbox_inches='tight')
    plt.close()
    print(f"   📊 Saved: {os.path.basename(path)}")


# ============================================================
# Figure 5: Prediction Stability
# ============================================================
def plot_prediction_stability(results):
    fig, ax = plt.subplots(figsize=(8, 5))

    configs = [r['config'] for r in results]
    flips = [r['stability_flips_vs_5seed'] for r in results]

    colors_bar = []
    for r in results:
        if r['config'] == 'G':
            colors_bar.append(COLOR_BASELINE)
        elif r['tta']:
            colors_bar.append(COLOR_TTA)
        else:
            colors_bar.append(COLOR_NO_TTA)

    bars = ax.bar(configs, flips, color=colors_bar, edgecolor='white', linewidth=0.8, width=0.6)

    for bar, f in zip(bars, flips):
        ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 0.15,
                str(f), ha='center', va='bottom', fontweight='bold', fontsize=11)

    # Legend
    legend_handles = [
        mpatches.Patch(color=COLOR_NO_TTA, label='No TTA'),
        mpatches.Patch(color=COLOR_TTA, label='With TTA'),
        mpatches.Patch(color=COLOR_BASELINE, label='Reference (Config G)'),
    ]
    ax.legend(handles=legend_handles, loc='upper right', frameon=True, fancybox=True, shadow=True)

    ax.set_xlabel('Configuration')
    ax.set_ylabel('Predictions Changed vs 5-Seed No-TTA')
    ax.set_title('Prediction Stability vs Full Ensemble')
    ax.set_ylim(0, max(flips) + 3 if max(flips) > 0 else 5)

    plt.tight_layout()
    path = os.path.join(DATA_DIR, 'ablation_prediction_stability.png')
    plt.savefig(path, dpi=200, bbox_inches='tight')
    plt.close()
    print(f"   📊 Saved: {os.path.basename(path)}")


# ============================================================
# Main
# ============================================================
def main():
    print("=" * 55)
    print("  ABLATION STUDY — Figure Generation (CPU-only)")
    print("=" * 55)

    data = load_results()
    results = data['results']

    print(f"\n📊 Generating figures...")
    plot_accuracy_by_seeds(results)
    plot_f1_by_seeds(results)
    plot_errors_by_config(results)
    plot_confidence_gap(results)
    plot_prediction_stability(results)

    print(f"\n✅ All figures saved to: {DATA_DIR}")
    print("   You can re-run this script to update styling without GPU inference.")


if __name__ == '__main__':
    main()
