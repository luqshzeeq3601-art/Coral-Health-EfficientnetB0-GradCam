import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from datetime import datetime, timedelta
import os

def create_gantt(tasks, filename, title, color='#2e7d32'):
    """
    Generates a professional, academic-style Gantt chart.
    'tasks' is a list of tuples: (Task Name, Start Date, End Date)
    """
    fig, ax = plt.subplots(figsize=(10, 6), facecolor='white')
    
    # Global font settings
    plt.rc('font', family='serif', size=11)
    
    # Process tasks
    task_names = [t[0] for t in tasks]
    start_dates = [datetime.strptime(t[1], "%Y-%m-%d") for t in tasks]
    end_dates = [datetime.strptime(t[2], "%Y-%m-%d") for t in tasks]
    durations = [(e - s).days for s, e in zip(start_dates, end_dates)]
    
    # Plotting horizontal bars (broken_barh style)
    for i, (name, start, duration) in enumerate(zip(task_names, start_dates, durations)):
        ax.barh(i, duration, left=start, height=0.5, align='center', color=color, alpha=0.8, edgecolor='black', linewidth=0.8)
        # Adding labels at the end of bars
        ax.text(start + timedelta(days=duration + 2), i, name, va='center', ha='left', fontsize=10)

    # Date formatting
    ax.xaxis.set_major_locator(mdates.WeekdayLocator(interval=2))
    ax.xaxis.set_major_formatter(mdates.DateFormatter("%d %b"))
    plt.xticks(rotation=45)
    
    # Appearance
    ax.set_yticks([]) # Hide y-axis task labels as they are on the bars
    ax.invert_yaxis()
    ax.set_title(title, pad=20, fontsize=14, fontweight='normal')
    ax.grid(True, axis='x', linestyle='--', alpha=0.3)
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.spines['left'].set_visible(False)
    
    plt.tight_layout()
    output_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), filename)
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    plt.close()
    print(f"[OK] Generated {filename}")

if __name__ == "__main__":
    # FYP 1 Data (Semester 7 - Based on Historical Records)
    fyp1_tasks = [
        ("Title Selection & Supervisor Allocation", "2025-10-01", "2025-10-14"),
        ("Literature Review & Chap 2 Drafting", "2025-10-15", "2025-11-15"),
        ("Methodology Planning (Chap 3)", "2025-11-16", "2025-12-15"),
        ("Progress Report 1 (FYP1)", "2025-11-01", "2025-11-07"),
        ("Progress Report 2 (FYP1)", "2025-12-08", "2025-12-14"),
        ("Proposal Defense / FYP1 Viva", "2026-01-05", "2026-01-12"),
        ("Final FYP1 Report Submission", "2026-01-20", "2026-02-15")
    ]
    
    # FYP 2 Data (Semester 8 - Current Timeline)
    fyp2_tasks = [
        ("Phase 1: Foundation & Setup", "2026-03-16", "2026-03-29"),
        ("Data Pipeline & Preprocessing", "2026-03-30", "2026-04-05"),
        ("EfficientNetB0 Base Training", "2026-04-06", "2026-04-12"),
        ("SWA Ensemble & Optimization", "2026-04-20", "2026-05-03"),
        ("98.11% Achievement Milestone", "2026-05-03", "2026-05-04"),
        ("Evaluation & Grad-CAM XAI", "2026-05-04", "2026-05-17"),
        ("Web Application Development", "2026-05-18", "2026-06-07"),
        ("Full Report Writing", "2026-06-08", "2026-06-26"),
        ("Final Viva Voce", "2026-06-29", "2026-07-05"),
        ("Final Submission", "2026-07-06", "2026-07-12")
    ]
    
    create_gantt(fyp1_tasks, "fyp1_gantt.png", "FYP 1: Foundation & Research Timeline", color='#1565c0') # Blue for FYP1
    create_gantt(fyp2_tasks, "fyp2_gantt.png", "FYP 2: Implementation & Deployment Timeline", color='#2e7d32') # Green for FYP2
