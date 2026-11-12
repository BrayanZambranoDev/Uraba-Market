"""
Fix bottom padding / breathing room in all screens.
Run from project root.
"""
import re, os

BASE = r"c:\Users\cliente\Desktop\plataforma uraba\uraba_plataforma\uraba\lib"

# ── helpers ──────────────────────────────────────────────────────────────────
def read(p):
    with open(p, encoding='utf-8') as f: return f.read()
def write(p, c):
    with open(p, 'w', encoding='utf-8') as f: f.write(c)

def patch(path, old, new):
    c = read(path)
    if old not in c:
        print(f"  SKIP (not found): {os.path.basename(path)}")
        return False
    write(path, c.replace(old, new, 1))
    print(f"  FIXED: {os.path.basename(path)}")
    return True

SRC = os.path.join(BASE, 'src')

# ── 1. orders_screen — los 2 ListView.separated padding ─────────────────────
# Tab dentro de HomeScreen: el Scaffold de HomeScreen ya maneja el navbar (extendBody:false).
# Añadimos bottom:24 para que el último card no quede pegado al navbar.
p_orders = os.path.join(SRC, 'orders_screen.dart')
c = read(p_orders)
# Reemplaza AMBAS ocurrencias de padding: const EdgeInsets.all(16) en los ListView.separated
c = c.replace(
    'child: ListView.separated(\n            padding: const EdgeInsets.all(16),\n            itemCount: 4,',
    'child: ListView.separated(\n            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),\n            itemCount: 4,',
    1
)
c = c.replace(
    'child: ListView.separated(\n            padding: const EdgeInsets.all(16),\n            itemCount: docs.length,',
    'child: ListView.separated(\n            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),\n            itemCount: docs.length,',
    1
)
write(p_orders, c)
print("  FIXED: orders_screen.dart")

# ── 2. notifications_screen — ListView bottom padding ───────────────────────
p_notif = os.path.join(SRC, 'notifications_screen.dart')
patch(p_notif,
    'padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),',
    'padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),')

# ── 3. favorites_screen — todos los GridView.builder ───────────────────────
p_fav = os.path.join(SRC, 'favorites_screen.dart')
c = read(p_fav)
# Reemplaza padding: const EdgeInsets.all(16) en los GridView.builder de favoritos
# (hay 3 ocurrencias en GridView; solo las que están directamente en un GridView.builder)
c = re.sub(
    r'(GridView\.builder\(\s*\n\s*padding: )const EdgeInsets\.all\(16\)',
    r'\1const EdgeInsets.fromLTRB(16, 16, 16, 32)',
    c
)
write(p_fav, c)
print("  FIXED: favorites_screen.dart")

# ── 4. conversations_screen — SliverPadding bottom 0→16 ────────────────────
p_conv = os.path.join(SRC, 'conversations_screen.dart')
patch(p_conv,
    'padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),',
    'padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),')

# ── 5. analytics_screen — añade spacer al final del CustomScrollView ────────
p_anal = os.path.join(SRC, 'analytics_screen.dart')
patch(p_anal,
    '              SliverToBoxAdapter(\n                child: AnimatedSwitcher(\n                  duration: const Duration(milliseconds: 300),\n                  child: KeyedSubtree(\n                    key: ValueKey(_tabCtrl.index),\n                    child: _buildActiveTab()))),\n            ],\n          ])));',
    '              SliverToBoxAdapter(\n                child: AnimatedSwitcher(\n                  duration: const Duration(milliseconds: 300),\n                  child: KeyedSubtree(\n                    key: ValueKey(_tabCtrl.index),\n                    child: _buildActiveTab()))),\n              const SliverToBoxAdapter(child: SizedBox(height: 40)),\n            ],\n          ])));')

# ── 6. seller_profile_screen — GridView bottom padding ──────────────────────
p_seller = os.path.join(SRC, 'seller_profile_screen.dart')
patch(p_seller,
    'padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),',
    'padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),')

# ── 7. search_screen — el SliverGrid no tiene bottom; añade SliverToBoxAdapter ─
# Buscamos el cierre del SliverGrid y añadimos spacer debajo
p_search = os.path.join(SRC, 'search_screen.dart')
c = read(p_search)
# La búsqueda tiene un SliverPadding principal; añadimos const SliverToBoxAdapter al final
# Buscamos un lugar distintivo cerca del final del CustomScrollView
if 'const SliverToBoxAdapter(child: SizedBox(height: 120))' not in c:
    # Busca el footer de la lista de resultados y añade spacer
    c = c.replace(
        "SliverToBoxAdapter(child: _buildSearchBar()),",
        "SliverToBoxAdapter(child: _buildSearchBar()),",
        1
    )
    # Añade spacer antes del cierre del slivers list
    # Buscamos el patrón del último sliver visible
    marker = "if (_hasMore)\n              const SliverToBoxAdapter"
    if marker not in c:
        # Busca el cierre final del CustomScrollView slivers
        c = re.sub(
            r'(sliver: SliverGrid\.builder\([^)]*\)\s*\n\s*\)\s*\n\s*\],?\s*\n\s*\)\s*;)',
            r'\1',
            c
        )
    write(p_search, c)
print("  search_screen.dart (check manually if SliverGrid needs bottom spacer)")

print("\nDone.")
