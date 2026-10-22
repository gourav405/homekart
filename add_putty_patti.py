#!/usr/bin/env python3
"""
Add Putty Patti, Flexible Blades, and POP Gurmala products to homekart DB:
Category: Putty & Patti (category_id = 7)
Subcategory: Putty Paati / Blade (subcategory_id = 22)
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
CATEGORY_ID = 7      # Putty & Patti
SUBCATEGORY_ID = 22  # Putty Paati / Blade
UNIT_PCS = 5         # Piece

products_data = [
    {
        "name": "Star Steel Putty Patti",
        "sku": "STAR-PUTTY-PATTI",
        "description": "Heavy-duty steel putty patti / scraper with handle for surface scraping, crack opening, and corner putty/POP application.",
        "variants": [
            # (sku, variant_name, buy, sell, mrp)
            ("STAR-PATTI-2IN", "2 Inch", 15.0, 25.0, 30.0),
            ("STAR-PATTI-3IN", "3 Inch", 20.0, 30.0, 40.0),
            ("STAR-PATTI-4IN", "4 Inch", 25.0, 40.0, 50.0),
            ("STAR-PATTI-5IN", "5 Inch", 30.0, 50.0, 60.0),
            ("STAR-PATTI-6IN", "6 Inch", 40.0, 65.0, 75.0),
            ("STAR-PATTI-8IN", "8 Inch", 55.0, 85.0, 100.0),
        ]
    },
    {
        "name": "Star Flexible Putty Blade",
        "sku": "STAR-PUTTY-BLADE",
        "description": "Flexible spring steel sheet hand blade (double patti) for wide, seamless wall putty and POP skimming.",
        "variants": [
            ("STAR-BLADE-6IN",  "6 Inch",  20.0, 35.0, 45.0),
            ("STAR-BLADE-8IN",  "8 Inch",  25.0, 45.0, 55.0),
            ("STAR-BLADE-10IN", "10 Inch", 35.0, 60.0, 75.0),
            ("STAR-BLADE-12IN", "12 Inch", 45.0, 75.0, 90.0),
        ]
    },
    {
        "name": "Star POP Gurmala (Plastering Trowel)",
        "sku": "STAR-POP-GURMALA",
        "description": "Rectangular steel plastering trowel (gurmala) with grip handle for applying, leveling, and smoothing POP and wall plaster.",
        "variants": [
            ("STAR-GURMALA-10X4IN", "10x4 Inch", 55.0, 85.0,  110.0),
            ("STAR-GURMALA-12X4IN", "12x4 Inch", 75.0, 120.0, 150.0),
        ]
    }
]

for p in products_data:
    # 1. Insert product
    cursor.execute("""
        INSERT INTO products 
            (name, sku, description, brand_id, category_id, subcategory_id, is_tintable, is_active, created_at, updated_at)
        VALUES (%s, %s, %s, %s, %s, %s, 0, 1, NOW(), NOW())
    """, (p["name"], p["sku"], p["description"], BRAND_ID, CATEGORY_ID, SUBCATEGORY_ID))
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
print("\n🎉 All Patti, Blades, and POP Gurmala products added successfully!")
