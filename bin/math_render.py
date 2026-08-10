#!/usr/bin/env python3
"""
公式渲染脚本：把 LaTeX 公式渲染成真排版 PNG 并输出 OSC 1337 序列（Nebula 支持显示）。
用法：
  echo '\\sqrt{x^2+y^2}' | python math_render.py [--width 40%]
  python math_render.py '\\frac{a}{b}' [--width 40%]
输出：OSC 1337 inline 图片序列（打印到终端即显示公式图片）
"""
import sys, io, base64, argparse
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

def render(formula: str, width: str = '40%', fontsize: int = 28, color: str = 'white') -> str:
    f = formula.strip()
    if f.startswith('$') and f.endswith('$'):
        f = f[1:-1].strip()
    if f.startswith('\\[') and f.endswith('\\]'):
        f = f[2:-2].strip()
    fig = plt.figure()
    fig.text(0.5, 0.5, f'${f}$', fontsize=fontsize, ha='center', va='center', color=color)
    buf = io.BytesIO()
    fig.savefig(buf, dpi=200, format='png', bbox_inches='tight', transparent=True)
    plt.close(fig)
    b64 = base64.b64encode(buf.getvalue()).decode()
    return f'\x1b]1337;File=inline=1;preserveAspectRatio=1;width={width}:{b64}\x07\n'

if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('formula', nargs='?', default=None)
    ap.add_argument('--width', default='40%')
    ap.add_argument('--fontsize', type=int, default=28)
    ap.add_argument('--color', default='white', help='文字颜色：暗色主题用 white，亮色主题用 black')
    args = ap.parse_args()
    text = args.formula if args.formula else sys.stdin.read()
    try:
        sys.stdout.write(render(text, args.width, args.fontsize, args.color))
    except Exception as e:
        sys.stderr.write(f'ERROR: {e}\n')
        sys.exit(1)
