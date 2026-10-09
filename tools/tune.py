"""Автотюнер цен под таймлайн ГДД (раздел 3).

Гоняет tools/simulate.luau и масштабирует цены покупок каждого этапа, пока длительности
этапов не совпадут с целевыми. Цены этапа 1 (ручной огород) не трогает.

Использование:  python3 tools/tune.py [путь к luau] [итераций]
"""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FILES = {
    "item": ROOT / "src/shared/Config/Items.luau",
    "research": ROOT / "src/shared/Config/Varieties.luau",
    "staff": ROOT / "src/shared/Config/Staff.luau",
}
# Начало этапов по ГДД (минуты) и конец — Rebirth
TARGET_START = {2: 10, 3: 30, 4: 60, 5: 95}
TARGET_END = 135


def fmt(n: float) -> str:
    n = int(n)
    s = str(n)
    if n < 10_000:
        return s
    parts = []
    while s:
        parts.insert(0, s[-3:])
        s = s[:-3]
    return "_".join(parts)


def round2(x: float) -> int:
    """Две значащие цифры."""
    if x < 100:
        return max(1, int(round(x)))
    digits = len(str(int(x))) - 2
    return int(round(x / 10**digits) * 10**digits)


def cost_span(text: str, ident: str):
    m = re.search(r'id = "%s",' % re.escape(ident), text)
    if not m:
        raise SystemExit(f"не найден {ident}")
    c = re.compile(r"\bcost = ([\d_]+)").search(text, m.end())
    return c


def read_cost(kind: str, ident: str, texts) -> int:
    return int(cost_span(texts[kind], ident).group(1).replace("_", ""))


def write_cost(kind: str, ident: str, value: int, texts) -> None:
    text = texts[kind]
    c = cost_span(text, ident)
    texts[kind] = text[: c.start()] + "cost = " + fmt(value) + text[c.end():]


def run_sim(luau: str):
    out = subprocess.run([luau, str(ROOT / "tools/simulate.luau"), "-a", "machine"], capture_output=True,
                         text=True, check=True).stdout
    buys, stages, end = [], {}, None
    for line in out.splitlines():
        parts = line.split()
        if parts[0] == "BUY":
            buys.append((parts[1], parts[2], int(parts[3]), float(parts[4])))
        elif parts[0] == "STAGE":
            stages[int(parts[1])] = float(parts[2]) / 60
        elif parts[0] == "END":
            end = float(parts[1]) / 60
    return buys, stages, end


def main() -> None:
    luau = sys.argv[1] if len(sys.argv) > 1 else "luau"
    iterations = int(sys.argv[2]) if len(sys.argv) > 2 else 8
    texts = {k: p.read_text(encoding="utf-8") for k, p in FILES.items()}
    exact = {}
    for it in range(iterations):
        buys, stages, end = run_sim(luau)
        shuttle_t = next(t for k, i, s, t in buys if i == "shuttle") / 60
        final_wait = end - shuttle_t
        actual = {
            2: stages[3] - stages[2],
            3: stages[4] - stages[3],
            4: stages[5] - stages[4],
            5: shuttle_t - stages[5],
        }
        target = {
            2: TARGET_START[3] - TARGET_START[2],
            3: TARGET_START[4] - TARGET_START[3],
            4: TARGET_START[5] - TARGET_START[4],
            5: TARGET_END - TARGET_START[5] - final_wait,
        }
        ratio = {s: target[s] / actual[s] for s in actual}
        print(f"итерация {it}: этапы " + ", ".join(f"{s}:{stages[s]:.1f}" for s in sorted(stages))
              + f", rebirth {end:.1f} мин; коэф. " + ", ".join(f"{s}:{ratio[s]:.2f}" for s in sorted(ratio)))
        if all(abs(r - 1) < 0.03 for r in ratio.values()):
            break
        seen = set()
        for kind, ident, stage, _ in buys:
            if (kind, ident) in seen or stage < 2:
                continue
            seen.add((kind, ident))
            key = (kind, ident)
            if key not in exact:
                exact[key] = float(read_cost(kind, ident, texts))
            exact[key] *= ratio[stage]
            write_cost(kind, ident, round2(exact[key]), texts)
        for k, p in FILES.items():
            p.write_text(texts[k], encoding="utf-8")


if __name__ == "__main__":
    main()
