"""
Replace remaining Material Icons with Iconsax equivalents across all dart files.
Run from the project root directory.
"""
import os
import re

BASE = r"c:\Users\cliente\Desktop\plataforma uraba\uraba_plataforma\uraba\lib"

# Global substitution map: (pattern, replacement)
# Order matters — more specific patterns first
REPLACEMENTS = [
    # ── Eco / Nature ──────────────────────────────────────────────────────
    (r"Icons\.eco_rounded", "Iconsax.tree"),
    (r"Icons\.grass_rounded", "Iconsax.tree"),
    (r"Icons\.park_rounded", "Iconsax.tree"),
    (r"Icons\.storefront_rounded", "Iconsax.shop"),
    (r"Icons\.trending_up_rounded", "Iconsax.trend_up"),

    # ── Cart / Shopping ───────────────────────────────────────────────────
    (r"Icons\.shopping_cart_outlined", "Iconsax.shopping_cart"),
    (r"Icons\.shopping_cart", "Iconsax.shopping_cart"),
    (r"Icons\.credit_card_rounded", "Iconsax.card_tick"),
    (r"Icons\.shield_outlined", "Iconsax.shield"),

    # ── Notifications ─────────────────────────────────────────────────────
    (r"Icons\.notifications_outlined", "Iconsax.notification"),
    (r"Icons\.notifications_rounded", "Iconsax.notification"),
    (r"Icons\.notification", "Iconsax.notification"),

    # ── Feed / Categories ─────────────────────────────────────────────────
    (r"Icons\.apps_rounded", "Iconsax.element_3"),
    (r"Icons\.people_rounded", "Iconsax.people"),
    (r"Icons\.tune_rounded", "Iconsax.setting_4"),
    (r"Icons\.feed_rounded", "Iconsax.document_text"),
    (r"Icons\.more_horiz_rounded", "Iconsax.more"),
    (r"Icons\.more_vert_rounded", "Iconsax.more"),
    (r"Icons\.more_vert", "Iconsax.more"),
    (r"Icons\.public_rounded", "Iconsax.global"),
    (r"Icons\.public", "Iconsax.global"),
    (r"Icons\.campaign_outlined", "Iconsax.notification"),
    (r"Icons\.text_fields_rounded", "Iconsax.text"),

    # ── Offer / Discount / Share ──────────────────────────────────────────
    (r"Icons\.local_offer_outlined", "Iconsax.discount_circle"),
    (r"Icons\.local_offer_rounded", "Iconsax.discount_circle"),
    (r"Icons\.share_outlined", "Iconsax.share"),
    (r"Icons\.share_rounded", "Iconsax.share"),

    # ── Send / Close ──────────────────────────────────────────────────────
    (r"Icons\.send_rounded", "Iconsax.send_1"),

    # ── Delete / Trash ────────────────────────────────────────────────────
    (r"Icons\.delete_outline_rounded", "Iconsax.trash"),
    (r"Icons\.delete_rounded", "Iconsax.trash"),
    (r"Icons\.delete_outline", "Iconsax.trash"),

    # ── Location / Map ────────────────────────────────────────────────────
    (r"Icons\.edit_location_rounded", "Iconsax.location"),
    (r"Icons\.home_work_rounded", "Iconsax.buildings_2"),
    (r"Icons\.signpost_rounded", "Iconsax.map"),
    (r"Icons\.map_rounded", "Iconsax.map"),
    (r"Icons\.place_rounded", "Iconsax.location"),
    (r"Icons\.place_outlined", "Iconsax.location"),
    (r"Icons\.location_on_rounded", "Iconsax.location"),
    (r"Icons\.location_on", "Iconsax.location"),

    # ── Auth / Email / Password ───────────────────────────────────────────
    (r"Icons\.mail_outline_rounded", "Iconsax.sms"),
    (r"Icons\.mail_outline", "Iconsax.sms"),
    (r"Icons\.visibility_outlined", "Iconsax.eye"),
    (r"Icons\.visibility_off_outlined", "Iconsax.eye_slash"),
    (r"Icons\.visibility_off", "Iconsax.eye_slash"),
    (r"Icons\.visibility\b", "Iconsax.eye"),
    (r"Icons\.error_outline", "Iconsax.warning_2"),

    # ── Check / Tick ──────────────────────────────────────────────────────
    (r"Icons\.check_circle_outline_rounded", "Iconsax.tick_circle"),
    (r"Icons\.check_circle_outline\b", "Iconsax.tick_circle"),
    (r"Icons\.check_circle_rounded", "Iconsax.tick_circle"),
    (r"Icons\.check_circle\b", "Iconsax.tick_circle"),
    (r"Icons\.check_rounded", "Iconsax.check"),
    (r"Icons\.check\b", "Iconsax.check"),

    # ── Order Status ──────────────────────────────────────────────────────
    (r"Icons\.schedule_rounded", "Iconsax.clock"),
    (r"Icons\.pending_rounded", "Iconsax.clock"),
    (r"Icons\.hourglass_top_rounded", "Iconsax.clock"),
    (r"Icons\.local_shipping_rounded", "Iconsax.truck"),
    (r"Icons\.local_shipping", "Iconsax.truck"),
    (r"Icons\.where_to_vote_rounded", "Iconsax.location_tick"),
    (r"Icons\.cancel_outlined", "Iconsax.close_circle"),
    (r"Icons\.cancel_rounded", "Iconsax.close_circle"),
    (r"Icons\.assignment_return_rounded", "Iconsax.undo"),
    (r"Icons\.assignment_turned_in_rounded", "Iconsax.tick_circle"),

    # ── Image / Gallery ───────────────────────────────────────────────────
    (r"Icons\.image\b", "Iconsax.gallery"),
    # Note: Icons.broken_image kept as Material (no equivalent)

    # ── Help / Info ───────────────────────────────────────────────────────
    (r"Icons\.help_rounded", "Iconsax.info_circle"),
    (r"Icons\.help_outline_rounded", "Iconsax.info_circle"),
    (r"Icons\.info_outline", "Iconsax.info_circle"),
    (r"Icons\.info_rounded", "Iconsax.info_circle"),

    # ── Minus / Remove ────────────────────────────────────────────────────
    (r"Icons\.remove_rounded", "Iconsax.minus_cirlce"),
    (r"Icons\.remove\b", "Iconsax.minus_cirlce"),
    (r"Icons\.add_rounded", "Iconsax.add_circle"),
    (r"Icons\.add\b", "Iconsax.add_circle"),

    # ── Close ─────────────────────────────────────────────────────────────
    (r"Icons\.close_rounded", "Iconsax.close_circle"),
    (r"Icons\.close\b", "Iconsax.close_circle"),

    # ── Misc ──────────────────────────────────────────────────────────────
    (r"Icons\.star_rounded", "Iconsax.star"),
    (r"Icons\.star_outlined", "Iconsax.star"),
    (r"Icons\.star_border_rounded", "Iconsax.star"),
    (r"Icons\.favorite_rounded", "Iconsax.heart"),
    (r"Icons\.favorite_border_rounded", "Iconsax.heart"),
    (r"Icons\.arrow_back_rounded", "Iconsax.arrow_left"),
    (r"Icons\.arrow_back_ios_rounded", "Iconsax.arrow_left"),
    (r"Icons\.arrow_forward_rounded", "Iconsax.arrow_right"),
    (r"Icons\.keyboard_arrow_down_rounded", "Iconsax.arrow_down"),
    (r"Icons\.keyboard_arrow_up_rounded", "Iconsax.arrow_up"),
    (r"Icons\.expand_more_rounded", "Iconsax.arrow_down"),
    (r"Icons\.expand_less_rounded", "Iconsax.arrow_up"),
    (r"Icons\.person_rounded", "Iconsax.user"),
    (r"Icons\.person_add_rounded", "Iconsax.user_add"),
    (r"Icons\.edit_rounded", "Iconsax.edit"),
    (r"Icons\.edit\b", "Iconsax.edit"),
    (r"Icons\.refresh_rounded", "Iconsax.refresh"),
]

def process_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        original = f.read()

    content = original
    for pattern, replacement in REPLACEMENTS:
        content = re.sub(pattern, replacement, content)

    if content != original:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

changed = []
for root, dirs, files in os.walk(BASE):
    # skip generated files
    dirs[:] = [d for d in dirs if d not in ['.dart_tool', 'build', '.pub-cache']]
    for fname in files:
        if fname.endswith('.dart'):
            path = os.path.join(root, fname)
            if process_file(path):
                changed.append(path.replace(BASE, 'lib'))

print(f"OK: Modified {len(changed)} files:")
for f in changed:
    print(f"  {f}")
