#!/usr/bin/env python3
"""
Add Rollers products to homekart DB:
Category: Rollers (category_id = 10)
Subcategories:
- 31: Paint Roller
- 32: Texture Roller
- 33: Roller Sleeve / Refill
Brand: Star (brand_id = 3)
Unit: Piece (unit_id = 5, PCS)
"""

import mysql.connector

db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Thinksys@123",
    database="homekart"
)
cursor = db.cursor(buffered=True)

BRAND_ID = 3         # Star
CATEGORY_ID = 10     # Rollers
UNIT_PCS = 5         # Piece

# Subcategories
SUBCAT_PAINT_ROLLER = 31
SUBCAT_TEXTURE_ROLLER = 32
SUBCAT_REFILL = 33

products_data = [
    {
        "name": "Star Wall Paint Roller (with Handle)",
        "sku": "STAR-PAINT-ROLLER",
        "subcat": SUBCAT_PAINT_ROLLER,
        "description": "High-density poly-fiber wall paint roller with ergonomic handle frame for smooth, lint-free application of emulsion and distemper.",
        "variants": [
            # (sku, variant_name, buy, sell, mrp)
            ("STAR-ROLLER-4IN", "4 Inch (Mini)", 35.0,  55.0,  70.0),
            ("STAR-ROLLER-6IN", "6 Inch",        60.0,  90.0, 115.0),
            ("STAR-ROLLER-7IN", "7 Inch",        75.0, 120.0, 150.0),
            ("STAR-ROLLER-9IN", "9 Inch",        95.0, 150.0, 190.0),
        ]
    },
    {
        "name": "Star Roller Sleeve / Refill",
        "sku": "STAR-ROLLER-REFILL",
        "subcat": SUBCAT_REFILL,
        "description": "Replacement fabric roller sleeve / refill for emulsion and primer application.",
        "variants": [
            ("STAR-REFILL-4IN", "4 Inch Refill", 18.0, 30.0,  40.0),
            ("STAR-REFILL-6IN", "6 Inch Refill", 30.0, 50.0,  65.0),
            ("STAR-REFILL-7IN", "7 Inch Refill", 40.0, 65.0,  85.0),
            ("STAR-REFILL-9IN", "9 Inch Refill", 50.0, 85.0, 110.0),
        ]
    },
    {
        "name": "Star Foam Mini Roller Set",
        "sku": "STAR-FOAM-ROLLER",
        "subcat": SUBCAT_PAINT_ROLLER,
        "description": "High-density foam mini roller set with handle frame for smooth finish on enamel, oil paints, doors, grills, and woodwork.",
        "variants": [
            ("STAR-FOAM-4IN", "4 Inch", 30.0, 50.0, 65.0),
        ]
    },
    {
        "name": "Star Designer Texture Roller",
        "sku": "STAR-TEXTURE-ROLLER",
        "subcat": SUBCAT_TEXTURE_ROLLER,
        "description": "Patterned rubber texture design roller with handle frame for wall art, texture paints, and interior decorative finishes.",
        "variants": [
            ("STAR-TEXT-7IN", "7 Inch", 150.0, 230.0, 290.0),
            ("STAR-TEXT-9IN", "9 Inch", 180.0, 280.0, 350.0),
        ]
    }
]

for p in products_data:
    # 1. Insert product
    cursor.execute("""
        INSERT INTO products 
            (name, sku, description, brand_id, category_id, subcategory_id, is_tintable, is_active, created_at, updated_at)
        VALUES (%s, %s, %s, %s, %s, %s, 0, 1, NOW(), NOW())
    """, (p["name"], p["sku"], p["description"], BRAND_ID, CATEGORY_ID, p["subcat"]))
    db.commit()
    product_id = cursor.lastrowid
    print(f"\n✅ Product added: {p['name']} (id={product_id}, sku={p['sku']})")

    # 2. Insert variants
    for (v_sku, v_name, buy, sell, mrp) in p["variants"]:
        cursor.execute("""
            INSERT INTO product_variants
                (product_id, sku, variant_name, pack_size, unit_id, purchase_price, selling_price, mrp, is_active, created_at, updated_at)
            VALUES (%s, %s, %s, 1.0, %s, %s, %s, %s, 1, NOW(), NOW())
        """, (product_id, v_sku, v_name, UNIT_PCS, buy, sell, mrp))
        db.commit()
        variant_id = cursor.lastrowid

        # 3. Insert inventory
        cursor.execute("""
            INSERT INTO inventory (product_variant_id, quantity)
            VALUES (%s, 0)
        """, (variant_id,))
        db.commit()
        print(f"   ↳ {v_sku} | {v_name} | Buy=₹{buy} Sell=₹{sell} MRP=₹{mrp} (vid={variant_id})")

cursor.close()
db.close()
print("\n🎉 All Paint Rollers, Refills, and Texture Rollers added successfully!")
