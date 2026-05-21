"""
Собирает все 16x16 PNG из texture_pack/textures в один атлас.
Каждый тайл окружён отступом 1px (clamp-padding) для предотвращения
артефактов при UV-сэмплинге.
Тайлы сортируются по алфавиту — индекс = позиция в отсортированном списке.
Рядом с атласом сохраняется atlas_map.json: { "name": index, ... }
"""

import os, math, json
from PIL import Image

TEXTURES_DIR = os.path.join(os.path.dirname(__file__), "textures")
OUT_DIR       = os.path.dirname(__file__)
OUT_IMAGE     = os.path.join(OUT_DIR, "atlas.png")
OUT_MAP       = os.path.join(OUT_DIR, "atlas_map.json")

TILE_SIZE     = 16
PAD           = 1          # отступ с каждой стороны
CELL_SIZE     = TILE_SIZE + PAD * 2   # 18px на ячейку

def collect_tiles():
    tiles = []
    for fname in sorted(os.listdir(TEXTURES_DIR)):
        if not fname.lower().endswith(".png"):
            continue
        path = os.path.join(TEXTURES_DIR, fname)
        try:
            img = Image.open(path)
            if img.width == TILE_SIZE and img.height == TILE_SIZE:
                tiles.append((os.path.splitext(fname)[0], img.convert("RGBA")))
        except Exception as e:
            print(f"  skip {fname}: {e}")
    return tiles

def best_grid(n):
    """Минимальный квадратный атлас (cols >= rows) без лишних строк."""
    cols = math.ceil(math.sqrt(n))
    rows = math.ceil(n / cols)
    return cols, rows

def build_atlas(tiles):
    n = len(tiles)
    cols, rows = best_grid(n)
    W = cols * CELL_SIZE
    H = rows * CELL_SIZE

    atlas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    index_map = {}

    for i, (name, img) in enumerate(tiles):
        col = i % cols
        row = i // cols
        x = col * CELL_SIZE + PAD
        y = row * CELL_SIZE + PAD

        # заполняем паддинг краевыми пикселями (clamp)
        px = img.load()
        cell = Image.new("RGBA", (CELL_SIZE, CELL_SIZE), (0, 0, 0, 0))
        cell.paste(img, (PAD, PAD))

        # верх/низ
        for cx in range(TILE_SIZE):
            cell.putpixel((PAD + cx, 0),             px[cx, 0])
            cell.putpixel((PAD + cx, CELL_SIZE - 1), px[cx, TILE_SIZE - 1])
        # лево/право
        for cy in range(TILE_SIZE):
            cell.putpixel((0,             PAD + cy), px[0,             cy])
            cell.putpixel((CELL_SIZE - 1, PAD + cy), px[TILE_SIZE - 1, cy])
        # углы
        cell.putpixel((0,             0),             px[0,             0])
        cell.putpixel((CELL_SIZE - 1, 0),             px[TILE_SIZE - 1, 0])
        cell.putpixel((0,             CELL_SIZE - 1), px[0,             TILE_SIZE - 1])
        cell.putpixel((CELL_SIZE - 1, CELL_SIZE - 1), px[TILE_SIZE - 1, TILE_SIZE - 1])

        atlas.paste(cell, (col * CELL_SIZE, row * CELL_SIZE))
        index_map[name] = i

    return atlas, index_map, cols, rows

def main():
    print("Сбор текстур...")
    tiles = collect_tiles()
    print(f"  найдено: {len(tiles)} тайлов 16x16")

    atlas, index_map, _, _ = build_atlas(tiles)

    atlas.save(OUT_IMAGE)
    with open(OUT_MAP, "w", encoding="utf-8") as f:
        json.dump({"cell": CELL_SIZE, "tile": TILE_SIZE, "pad": PAD,
                   "map": index_map}, f, indent=2)

    print(f"  {len(index_map)} tiles -> {OUT_IMAGE}")

if __name__ == "__main__":
    main()
