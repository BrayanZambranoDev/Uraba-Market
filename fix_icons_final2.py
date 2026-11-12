"""
Second pass - replace remaining Material Icons with Iconsax equivalents.
"""
import os
import re

BASE = r"c:\Users\cliente\Desktop\plataforma uraba\uraba_plataforma\uraba\lib"

REPLACEMENTS = [
    # Order statuses
    (r"Icons\.assignment_late_rounded", "Iconsax.clock"),
    (r"Icons\.receipt_long_outlined", "Iconsax.receipt_2"),
    (r"Icons\.receipt_long_rounded", "Iconsax.receipt_2"),
    (r"Icons\.receipt_rounded", "Iconsax.receipt_2"),
    (r"Icons\.receipt_outlined", "Iconsax.receipt_2"),
    (r"Icons\.open_in_new_rounded", "Iconsax.export_3"),
    (r"Icons\.open_in_new", "Iconsax.export_3"),
    (r"Icons\.rate_review_outlined", "Iconsax.star"),
    (r"Icons\.rate_review_rounded", "Iconsax.star"),

    # Products / inventory
    (r"Icons\.inventory_2_outlined", "Iconsax.box"),
    (r"Icons\.inventory_2_rounded", "Iconsax.box"),
    (r"Icons\.inventory_outlined", "Iconsax.box"),
    (r"Icons\.inventory_rounded", "Iconsax.box"),
    (r"Icons\.category_outlined", "Iconsax.category"),
    (r"Icons\.category_rounded", "Iconsax.category"),
    (r"Icons\.layers_outlined", "Iconsax.element_3"),
    (r"Icons\.layers_rounded", "Iconsax.element_3"),

    # Money / payment
    (r"Icons\.attach_money_rounded", "Iconsax.dollar_circle"),
    (r"Icons\.attach_money", "Iconsax.dollar_circle"),
    (r"Icons\.payment_rounded", "Iconsax.card_tick"),
    (r"Icons\.payment\b", "Iconsax.card_tick"),
    (r"Icons\.savings_rounded", "Iconsax.wallet"),
    (r"Icons\.savings\b", "Iconsax.wallet"),
    (r"Icons\.account_balance_wallet_rounded", "Iconsax.wallet"),
    (r"Icons\.account_balance_wallet\b", "Iconsax.wallet"),
    (r"Icons\.account_balance_rounded", "Iconsax.buildings_2"),
    (r"Icons\.account_balance\b", "Iconsax.buildings_2"),
    (r"Icons\.verified_user_rounded", "Iconsax.shield_tick"),
    (r"Icons\.verified_user\b", "Iconsax.shield_tick"),

    # Shopping
    (r"Icons\.shopping_bag_outlined", "Iconsax.bag"),
    (r"Icons\.shopping_bag_rounded", "Iconsax.bag"),
    (r"Icons\.shopping_bag\b", "Iconsax.bag"),
    (r"Icons\.storefront_outlined", "Iconsax.shop"),
    (r"Icons\.remove_shopping_cart_outlined", "Iconsax.bag_cross"),
    (r"Icons\.remove_shopping_cart_rounded", "Iconsax.bag_cross"),

    # Date / time
    (r"Icons\.calendar_today_outlined", "Iconsax.clock"),
    (r"Icons\.calendar_today_rounded", "Iconsax.clock"),
    (r"Icons\.calendar_today\b", "Iconsax.clock"),

    # Address / home
    (r"Icons\.holiday_village_outlined", "Iconsax.buildings_2"),
    (r"Icons\.holiday_village_rounded", "Iconsax.buildings_2"),
    (r"Icons\.home_outlined", "Iconsax.home"),
    (r"Icons\.home_rounded\b", "Iconsax.home"),
    (r"Icons\.phone_outlined", "Iconsax.call"),
    (r"Icons\.phone_rounded", "Iconsax.call"),
    (r"Icons\.phone\b", "Iconsax.call"),

    # Chat / communication
    (r"Icons\.replay_rounded", "Iconsax.undo"),
    (r"Icons\.chat_outlined", "Iconsax.message"),
    (r"Icons\.chat_rounded", "Iconsax.message"),
    (r"Icons\.chat_bubble_outline_rounded", "Iconsax.message"),
    (r"Icons\.chat_bubble_outline\b", "Iconsax.message"),

    # Misc icons
    (r"Icons\.circle_outlined", "Iconsax.info_circle"),
    (r"Icons\.help_outline\b", "Iconsax.info_circle"),
    (r"Icons\.agriculture_outlined", "Iconsax.tree"),
    (r"Icons\.agriculture_rounded", "Iconsax.tree"),
    (r"Icons\.flag_outlined", "Iconsax.flag"),
    (r"Icons\.flag_rounded", "Iconsax.flag"),
    (r"Icons\.notes_rounded", "Iconsax.document_text"),
    (r"Icons\.notes\b", "Iconsax.document_text"),
    (r"Icons\.camera_alt_outlined", "Iconsax.camera"),
    (r"Icons\.camera_alt_rounded", "Iconsax.camera"),
    (r"Icons\.camera_alt\b", "Iconsax.camera"),
    (r"Icons\.photo_library_outlined", "Iconsax.gallery"),
    (r"Icons\.photo_library_rounded", "Iconsax.gallery"),
    (r"Icons\.photo_library\b", "Iconsax.gallery"),
    (r"Icons\.photo_outlined", "Iconsax.gallery"),
    (r"Icons\.photo_rounded", "Iconsax.gallery"),
    (r"Icons\.filter_list_rounded", "Iconsax.sort"),
    (r"Icons\.filter_list\b", "Iconsax.sort"),
    (r"Icons\.search_rounded", "Iconsax.search_normal"),
    (r"Icons\.search\b", "Iconsax.search_normal"),
    (r"Icons\.star_half_rounded", "Iconsax.star"),
    (r"Icons\.star_half\b", "Iconsax.star"),
    (r"Icons\.lock_outlined", "Iconsax.lock"),
    (r"Icons\.lock_rounded", "Iconsax.lock"),
    (r"Icons\.lock_open_rounded", "Iconsax.lock"),
    (r"Icons\.security_rounded", "Iconsax.shield"),
    (r"Icons\.verified_rounded", "Iconsax.verify"),
    (r"Icons\.verified\b", "Iconsax.verify"),
    (r"Icons\.bookmark_border_rounded", "Iconsax.bookmark"),
    (r"Icons\.bookmark_rounded", "Iconsax.bookmark"),
    (r"Icons\.whatsapp\b", "Iconsax.call"),
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
    dirs[:] = [d for d in dirs if d not in ['.dart_tool', 'build', '.pub-cache']]
    for fname in files:
        if fname.endswith('.dart'):
            path = os.path.join(root, fname)
            if process_file(path):
                changed.append(path.replace(BASE, 'lib'))

print(f"OK: Modified {len(changed)} files:")
for f in changed:
    print(f"  {f}")
