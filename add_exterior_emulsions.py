#!/usr/bin/env python3
"""
Add 2 missing Nerolac Exterior Emulsions to homekart DB:
1. Excel Total     (subcategory_id=5, Weatherproof Exterior Emulsion)
2. Excel Everlast  (subcategory_id=6, High Sheen & Dirtproof Emulsion)

All products:
- brand_id = 1 (Nerolac)
- category_id = 2 (Exterior Emulsion)
- is_tintable = 1
- is_active = 1
- Pack sizes: 1L, 4L, 10L, 20L
- Bases: White (id=38), Base 1 through Base 9 (ids 39-47) -> 10 shades x 4 sizes = 40 variants each
- Inventory row created for each variant (quantity = 0)
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
CATEGORY_ID = 2  # Exterior Emulsion
UNIT_L = 1       # Litre

shades = [
    ("White",  38, "WHI"),
    ("Base 1", 39, "BAS1"),
    ("Base 2", 40, "BAS2"),
    ("Base 3", 41, "BAS3"),
    ("Base 4", 42, "BAS4"),
    ("Base 5", 43, "BAS5"),
    ("Base 6", 44, "BAS6"),
    ("Base 7", 45, "BAS7"),
    ("Base 8", 46, "BAS8"),
    ("Base 9", 47, "BAS9"),
]

sizes = [1.0, 4.0, 10.0, 20.0]

products_to_add = [
    {
        "name": "Excel Total",
        "sku": "NER-EXCEL-TOT",
        "subcategory_id": 5,  # Weatherproof Exterior Emulsion
        "description": "High-performance water-based acrylic exterior emulsion with siloxane polymers and Heat Guard all-weather protection.",
        "sku_prefix": "NER-XTOT"
    },
    {
        "name": "Excel Everlast",
        "sku": "NER-EXCEL-EVR",
        "subcategory_id": 6,  # High Sheen & Dirtproof Emulsion
        "description": "Premium exterior wall emulsion with polyurethane-silicon hybrid formulation, high UV resistance, and low dust pick-up.",
        "sku_prefix": "NER-XEVR"
    }
]

for prod in products_to_add:
    # 1. Insert product
    cursor.execute("""
        INSERT INTO products 
            (name, sku, description, brand_id, category_id, subcategory_id, is_tintable, is_active, created_at, updated_at)
        VALUES (%s, %s, %s, %s, %s, %s, 1, 1, NOW(), NOW())
    """, (prod["name"], prod["sku"], prod["description"], BRAND_ID, CATEGORY_ID, prod["subcategory_id"]))
    db.commit()
    product_id = cursor.lastrowid
    print(f"✅ Product inserted: {prod['name']} (id={product_id}, sku={prod['sku']})")

    # 2. Insert variants (10 shades x 4 sizes = 40 variants)
    for (shade_name, color_id, shade_code) in shades:
        for size in sizes:
            size_label = f"{int(size)}L"
            v_sku = f"{prod['sku_prefix']}-{shade_code}-{size_label}"
            
            cursor.execute("""
                INSERT INTO product_variants
                    (product_id, sku, color_id, pack_size, unit_id,
                     purchase_price, selling_price, mrp,
                     is_active, created_at, updated_at)
                VALUES (%s, %s, %s, %s, %s, 0.00, 0.00, 0.00, 1, NOW(), NOW())
            """, (product_id, v_sku, color_id, size, UNIT_L))
            db.commit()
            variant_id = cursor.lastrowid

            # 3. Insert inventory
            cursor.execute("""
                INSERT INTO inventory (product_variant_id, quantity)
                VALUES (%s, 0)
            """, (variant_id,))
            db.commit()

    print(f"   ↳ Added 40 variants (White + Base 1-9 x 1L, 4L, 10L, 20L) for {prod['name']}")

cursor.close()
db.close()
print("\n🎉 Completed successfully!")
