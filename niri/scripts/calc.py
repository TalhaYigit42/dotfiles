#!/usr/bin/env python3
"""Calculator for developers: rofi prompt -> result copied. Understands 2**10, 0xff, 0b101, hex(255), bin(5),
sqrt(2), pi, sin(), log(), gcd(), and kb/mb/gb (1024-based).  usage: calc.py ["expr"]"""
import ast, math, subprocess, sys

NS = {k: getattr(math, k) for k in dir(math) if not k.startswith("_")}
NS.update(hex=hex, bin=bin, oct=oct, abs=abs, round=round, min=min, max=max, int=int, float=float, pow=pow,
          kb=1024, mb=1024**2, gb=1024**3, tb=1024**4)


def calc(expr):
    expr = expr.strip().replace("^", "**").replace(",", ".") if "(" not in expr else expr.strip().replace("^", "**")
    if "__" in expr or any(w in expr for w in ("import", "lambda", "[", "]", "{", "}", "'", '"', ";")):
        raise ValueError("not allowed")
    tree = ast.parse(expr, mode="eval")
    for n in ast.walk(tree):
        if isinstance(n, (ast.Attribute, ast.Subscript, ast.Dict, ast.Set, ast.List, ast.Starred, ast.Await)):
            raise ValueError("not allowed")
    return eval(compile(tree, "<calc>", "eval"), {"__builtins__": {}}, NS)


def fmt(v):
    if isinstance(v, float):
        return f"{v:.10g}"
    return str(v)


def main():
    expr = " ".join(sys.argv[1:])
    if not expr:
        p = subprocess.run(["rofi", "-dmenu", "-p", "calc", "-theme", __import__("os").path.expanduser("~/.config/niri/rofi.rasi")],
                           input="", capture_output=True, text=True)
        expr = p.stdout.strip()
    if not expr:
        return
    try:
        res = fmt(calc(expr))
    except Exception as e:
        if len(sys.argv) > 1:
            print(f"error: {e}", file=sys.stderr)
        else:
            subprocess.run(["notify-send", "-t", "3000", "calc", f"error: {e}"])
        return
    if len(sys.argv) > 1:
        print(res)
        return
    subprocess.run(["wl-copy", res])
    subprocess.run(["notify-send", "-t", "4000", "calc", f"{expr} = {res}  (copied)"])


main()
