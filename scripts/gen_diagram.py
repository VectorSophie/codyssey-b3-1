"""Generate architecture diagram PNG for b6-1."""
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch

fig, ax = plt.subplots(figsize=(12, 9))
ax.set_xlim(0, 12)
ax.set_ylim(0, 9)
ax.axis('off')
fig.patch.set_facecolor('#1C1F26')

def box(x, y, w, h, fc, ec, lw=1.5, radius=0.3):
    return FancyBboxPatch((x, y), w, h,
                          boxstyle=f"round,pad=0,rounding_size={radius}",
                          facecolor=fc, edgecolor=ec, linewidth=lw)

def label(ax, x, y, text, size=8, color='#C9D1DC', bold=False, ha='center'):
    weight = 'bold' if bold else 'normal'
    ax.text(x, y, text, ha=ha, va='center', fontsize=size,
            color=color, fontweight=weight, fontfamily='monospace')

def arrow(ax, x1, y1, x2, y2, color='#7FB7C9'):
    ax.annotate('', xy=(x2, y2), xytext=(x1, y1),
                arrowprops=dict(arrowstyle='->', color=color, lw=1.8))

# ── Title
ax.text(6, 8.6, 'b6-1 Architecture — VPC / EC2 / Nginx',
        ha='center', va='center', fontsize=13, color='#7FB7C9',
        fontweight='bold', fontfamily='monospace')

# ── Internet box
inet = box(4.5, 7.3, 3, 0.9, '#252830', '#7A848E', lw=1)
ax.add_patch(inet)
label(ax, 6, 7.75, 'Internet', size=10, color='#C9D1DC')

# ── Arrow Internet → IGW
arrow(ax, 6, 7.3, 6, 6.6)

# ── IGW box
igw = box(4.2, 6.0, 3.6, 0.55, '#2D3544', '#7FB7C9', lw=1.5)
ax.add_patch(igw)
label(ax, 6, 6.275, 'Internet Gateway  igw-0216170a9e1876f6f', size=8, color='#7FB7C9')

# ── Arrow IGW → VPC
arrow(ax, 6, 6.0, 6, 5.35)

# ── VPC outer
vpc = box(0.5, 0.5, 11, 4.75, '#1E2128', '#D9B36A', lw=2)
ax.add_patch(vpc)
label(ax, 1.4, 5.1, 'VPC  10.0.0.0/16  (vpc-023d852a3471ef158)',
      size=8.5, color='#D9B36A', ha='left')

# ── Public Subnet
sub = box(1.0, 1.0, 10, 3.5, '#252830', '#7BBF8E', lw=1.5)
ax.add_patch(sub)
label(ax, 1.8, 4.37, 'Public Subnet  10.0.1.0/24  ap-northeast-2a  (subnet-01c319e79337bc3b0)',
      size=7.5, color='#7BBF8E', ha='left')

# ── Route Table note
rt_box = box(1.3, 3.25, 3.2, 0.9, '#1C1F26', '#7A848E', lw=1)
ax.add_patch(rt_box)
label(ax, 2.9, 3.82, 'Route Table', size=8, color='#7A848E')
label(ax, 2.9, 3.52, '0.0.0.0/0 → IGW', size=7.5, color='#7FB7C9')

# ── EC2 box
ec2 = box(5.5, 1.35, 5.0, 2.8, '#2D3544', '#7FB7C9', lw=2)
ax.add_patch(ec2)
label(ax, 8.0, 3.85, 'EC2  t3.micro', size=9, color='#7FB7C9', bold=True)
label(ax, 8.0, 3.48, 'i-05d106a3c3409edd4', size=7.5, color='#7A848E')
label(ax, 8.0, 3.13, 'Public IP: 54.180.237.44', size=8, color='#D9B36A')
label(ax, 8.0, 2.78, 'Ubuntu 22.04 LTS', size=7.5, color='#7A848E')
label(ax, 8.0, 2.42, 'Nginx 1.x  (web server)', size=8.5, color='#C9D1DC')
label(ax, 8.0, 2.05, 'GET /health → 200 OK', size=8, color='#7BBF8E')
label(ax, 8.0, 1.70, 'EBS gp3  8 GiB', size=7.5, color='#7A848E')

# ── Security Group badge
sg = box(5.6, 1.42, 4.8, 0.5, '#1C1F26', '#C0544B', lw=1)
ax.add_patch(sg)
label(ax, 8.0, 1.67, '', size=7)  # spacing
label(ax, 8.0, 1.57, 'SG: HTTP 80 ← 0.0.0.0/0  |  SSH 22 ← 121.135.181.35/32',
      size=7, color='#C0544B')

# Traffic flow arrow: Internet → EC2
ax.annotate('', xy=(8.0, 4.15), xytext=(6.0, 5.95),
            arrowprops=dict(arrowstyle='->', color='#7FB7C9', lw=2,
                            connectionstyle='arc3,rad=0.2'))
label(ax, 7.6, 5.2, 'HTTP :80', size=7.5, color='#7FB7C9')

# ── Legend
legend_items = [
    mpatches.Patch(color='#D9B36A', label='VPC'),
    mpatches.Patch(color='#7BBF8E', label='Public Subnet'),
    mpatches.Patch(color='#7FB7C9', label='EC2 / IGW'),
    mpatches.Patch(color='#C0544B', label='Security Group'),
]
ax.legend(handles=legend_items, loc='lower left', bbox_to_anchor=(0.01, 0.01),
          framealpha=0.2, facecolor='#252830', edgecolor='#363A44',
          labelcolor='#C9D1DC', fontsize=8)

plt.tight_layout(pad=0.5)
plt.savefig('C:/Workspace/codyssey/codyssey-b6-1/docs/architecture.png',
            dpi=150, bbox_inches='tight', facecolor='#1C1F26')
print("diagram saved → docs/architecture.png")
