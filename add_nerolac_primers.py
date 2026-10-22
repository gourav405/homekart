#!/usr/bin/env python3
"""
Add 4 missing Nerolac Primers to homekart DB:
1. Nerolac Economy Interior Primer  (subcategory_id=14, Interior Wall Primer)
2. Nerolac Interior Primer           (subcategory_id=14, Interior Wall Primer)
3. Nerolac Economy Exterior Primer   (subcategory_id=15, Exterior Wall Primer)
4. Nerolac Suraksha Primer           (subcategory_id=15, Exterior Wall Primer)
All: brand_id=1, category_id=6 (Primers), White color (id=38), is_tintable=0
Pack sizes: 1L, 4L, 10L, 20L for each
"""

import mysql.connector

db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Thinksys@123",
    database="homekart"
)
cursor = db.cursor(buffered=True)

BRAND_ID = 1
CATEGORY_ID = 6       # Primers
SUBCAT_INTERIOR = 14  # Interior Wall Primer
SUBCAT_EXTERIOR = 15  # Exterior Wall Primer
WHITE_COLOR_ID = 38
UNIT_ID = 1           # Litre

# -------------------------------------------------------------------
# Product definitions
# variants: (variant_sku_suffix, pack_size, purchase_price, selling_price, mrp)
# -------------------------------------------------------------------
products = [
    {
        "name": "Nerolac Economy Interior Primer",
        "sku": "NERO-ECO-INT-PRM",
        "subcategory_id": SUBCAT_INTERIOR,
        "description": "Budget-friendly water-thinnable interior wall primer. Reduces surface porosity and improves adhesion of distempers and economy emulsions on interior plastered surfaces.",
        "variants": [
            ("1L",  1.0,  110.0,  135.0,  150.0),
            ("4L",  4.0,  410.0,  490.0,  560.0),
            ("10L", 10.0, 950.0,  1150.0, 1300.0),
            ("20L", 20.0, 1700.0, 2000.0, 2200.0),
        ],
    },
    {
        "name": "Nerolac Interior Primer",
        "sku": "NERO-INT-PRM",
        "subcategory_id": SUBCAT_INTERIOR,
        "description": "Standard quality water-based interior wall primer. Deeply penetrates and seals porous interior surfaces providing a smooth base for emulsion paints and distempers.",
        "variants": [
            ("1L",  1.0,  140.0,  175.0,  200.0),
            ("4L",  4.0,  530.0,  650.0,  750.0),
            ("10L", 10.0, 1200.0, 1450.0, 1650.0),
            ("20L", 20.0, 2100.0, 2550.0, 2900.0),
        ],
    },
    {
        "name": "Nerolac Economy Exterior Primer",
        "sku": "NERO-ECO-EXT-PRM",
        "subcategory_id": SUBCAT_EXTERIOR,
        "description": "Budget-friendly water-thinnable exterior wall primer. Prevents chalking, provides good opacity and whiteness as a base coat for exterior emulsions on masonry, cement plaster and concrete.",
        "variants": [
            ("1L",  1.0,  130.0,  160.0,  185.0),
            ("4L",  4.0,  700.0,  850.0,  950.0),
            ("10L", 10.0, 1200.0, 1450.0, 1650.0),
            ("20L", 20.0, 1900.0, 2300.0, 2600.0),
        ],
    },
    {
        "name": "Nerolac Suraksha Primer",
        "sku": "NERO-SURAKSHA-PRM",
        "subcategory_id": SUBCAT_EXTERIOR,
        "description": "Water-based acrylic copolymer exterior wall primer. Provides high whiteness, excellent opacity and strong adhesion for exterior topcoats. Does not require water curing.",
        "variants": [
            ("1L",  1.0,  150.0,  190.0,  220.0),
            ("4L",  4.0,  570.0,  700.0,  820.0),
            ("10L", 10.0, 1350.0, 1650.0, 1900.0),
            ("20L", 20.0, 2200.0, 2700.0, 3100.0),
        ],
    },
]

# -------------------------------------------------------------------
# Insert
# -------------------------------------------------------------------
for prod in products:
    # 1. Insert product (with sku field)
    cursor.execute("""
        INSERT INTO products
            (name, sku, description, brand_id, category_id, subcategory_id, is_tintable, is_active, created_at, updated_at)
        VALUES (%s, %s, %s, %s, %s, %s, 0, 1, NOW(), NOW())
    """, (prod["name"], prod["sku"], prod["description"], BRAND_ID, CATEGORY_ID, prod["subcategory_id"]))
    db.commit()
    product_id = cursor.lastrowid
    print(f"✅ Inserted product: {prod['name']} (id={product_id}, sku={prod['sku']})")

    # 2. Insert variants
    for (suffix, pack_size, purchase, selling, mrp) in prod["variants"]:
        variant_sku = f"{prod['sku']}-{suffix}"
        cursor.execute("""
            INSERT INTO product_variants
                (product_id, sku, color_id, pack_size, unit_id,
                 purchase_price, selling_price, mrp,
                 is_active, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 1, NOW(), NOW())
        """, (product_id, variant_sku, WHITE_COLOR_ID, pack_size, UNIT_ID, purchase, selling, mrp))
        db.commit()
        variant_id = cursor.lastrowid

        # 3. Insert inventory row
        cursor.execute("""
            INSERT INTO inventory (product_variant_id, quantity)
            VALUES (%s, 0)
        """, (variant_id,))
        db.commit()
        print(f"   ↳ {variant_sku} | {pack_size}L | Buy={purchase} Sell={selling} MRP={mrp} | vid={variant_id}")

print("\n🎉 All 4 primers inserted successfully!")
cursor.close()
db.close()
