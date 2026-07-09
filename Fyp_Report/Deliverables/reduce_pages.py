import sys

file_path = r'C:\Users\ZeeqRyz\Desktop\CHI\BASEPROJECT\Fyp_Report\Deliverables\generate_viva_qa.py'
with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
page_break_count = 0

for line in lines:
    # Reduce font size and add narrow margins
    if line.strip() == 'font.size = Pt(11)':
        new_lines.append('font.size = Pt(10)\n')
        new_lines.append('style.paragraph_format.line_spacing = 1.0\n')
        new_lines.append('style.paragraph_format.space_after = Pt(2)\n')
        new_lines.append('for section in doc.sections:\n')
        new_lines.append('    section.top_margin = Inches(0.5)\n')
        new_lines.append('    section.bottom_margin = Inches(0.5)\n')
        new_lines.append('    section.left_margin = Inches(0.5)\n')
        new_lines.append('    section.right_margin = Inches(0.5)\n')
        continue
    
    # Change add_spacer to do nothing instead of adding a paragraph
    if 'def add_spacer():' in line:
        new_lines.append(line)
        new_lines.append('    pass\n')
        continue
    if 'doc.add_paragraph()' in line and len(new_lines) > 0 and 'def add_spacer():' in new_lines[-2]:
        # Skip the doc.add_paragraph inside add_spacer
        continue
        
    # Remove page breaks except the first one
    if 'doc.add_page_break()' in line:
        page_break_count += 1
        if page_break_count > 1:
            # Comment out the extra page breaks
            new_lines.append('    # doc.add_page_break()\n')
            continue
            
    # Adjust question font size
    if 'run.font.size = Pt(12)' in line:
        new_lines.append('    run.font.size = Pt(10.5)\n')
        continue

    new_lines.append(line)

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
print('Script modified successfully!')
