#!/usr/bin/env python3
"""
Add White Cement and POP (Plaster of Paris) for Birla White and JK:
1. Brands: Birla White, JK
2. Subcategories under Putty & Patti (category_id=7):
   - White Cement
   - Plaster of Paris (POP)
3. Products & Variants:
   - Birla White Cement (1kg, 5kg, 25kg, 50kg)
   - Birla White POP    (1kg, 2kg, 20kg, 25kg, 40kg)
   - JK White Cement    (1kg, 5kg, 25kg, 50kg)
   - JK POP             (1kg, 2kg, 20kg, 25kg, 40kg)
All with inventory records initialized (quantity = 0).
"""

import mysql.connector

db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Thinksys@123",
    database="homekart"
)
cursor = db.cursor(buffered=True)

CATEGORY_ID = 7  # Putty & Patti
UNIT_KG = 3      # Kilogram

# 1. Brands
brands = [
    ("Birla White", "Birla White (UltraTech Cement)"),
    ("JK", "JK Cement / JK White Cement")
]
brand_ids = {}
for b_name, b_desc in brands:
    cursor.execute("SELECT id FROM brands WHERE name = %s", (b_name,))
    row = cursor.fetchone()
    if row:
        brand_ids[b_name] = row[0]
    else:
        cursor.execute("INSERT INTO brands (name, description, is_active, created_at, updated_at) VALUES (%s, %s, 1, NOW(), NOW())", (b_name, b_desc))
        db.commit()
        brand_ids[b_name] = cursor.lastrowid
    print(f"Brand: {b_name} -> id={brand_ids[b_name]}")

# 2. Subcategories under Category 7
subcats = [
    "White Cement",
    "Plaster of Paris (POP)"
]
subcat_ids = {}
for s_name in subcats:
    cursor.execute("SELECT id FROM subcategories WHERE name = %s AND category_id = %s", (s_name, CATEGORY_ID))
    row = cursor.fetchone()
    if row:
        subcat_ids[s_name] = row[0]
    else:
        cursor.execute("INSERT INTO subcategories (name, category_id, is_active, created_at, updated_at) VALUES (%s, %s, 1, NOW(), NOW())", (s_name, CATEGORY_ID))
        db.commit()
        subcat_ids[s_name] = cursor.lastrowid
    print(f"Subcategory: {s_name} -> id={subcat_ids[s_name]}")

# 3. Products & Variants definition
products_data = [
    # ── Birla White ──
    {
        "name": "Birla White Cement",
        "brand": "Birla White",
        "subcat": "White Cement",
        "sku": "BW-WHT-CEM",
        "desc": "Birla White Portland White Cement for surface finishing, architectural designs, tile grouting, and marble flooring.",
        "variants": [
            # (sku, pack_size, buy, sell, mrp)
            ("BW-WHT-CEM-1KG",   1.0,  28.0,   38.0,   45.0),
            ("BW-WHT-CEM-5KG",   5.0, 115.0,  145.0,  165.0),
            ("BW-WHT-CEM-25KG", 25.0, 460.0,  540.0,  600.0),
            ("BW-WHT-CEM-50KG", 50.0, 880.0, 1020.0, 1150.0),
        ]
    },
    {
        "name": "Birla White POP",
        "brand": "Birla White",
        "subcat": "Plaster of Paris (POP)",
        "sku": "BW-POP",
        "desc": "Birla White superfine Plaster of Paris (POP) for false ceilings, decorative moldings, cornices, and smooth wall leveling.",
        "variants": [
            ("BW-POP-1KG",   1.0,  15.0,  25.0,  30.0),
            ("BW-POP-2KG",   2.0,  30.0,  45.0,  55.0),
            ("BW-POP-20KG", 20.0, 160.0, 210.0, 250.0),
            ("BW-POP-25KG", 25.0, 190.0, 245.0, 285.0),
            ("BW-POP-40KG", 40.0, 290.0, 370.0, 420.0),
        ]
    },
    # ── JK ──
    {
        "name": "JK White Cement",
        "brand": "JK",
        "subcat": "White Cement",
        "sku": "JK-WHT-CEM",
        "desc": "JK Cement WhiteMaxX / JK White Portland Cement for decorative white concrete, wall repairs, marble laying, and tile joint filling.",
        "variants": [
            ("JK-WHT-CEM-1KG",   1.0,  28.0,   38.0,   45.0),
            ("JK-WHT-CEM-5KG",   5.0, 110.0,  140.0,  160.0),
            ("JK-WHT-CEM-25KG", 25.0, 450.0,  530.0,  590.0),
            ("JK-WHT-CEM-50KG", 50.0, 860.0, 1000.0, 1120.0),
        ]
    },
    {
        "name": "JK POP",
        "brand": "JK",
        "subcat": "Plaster of Paris (POP)",
        "sku": "JK-POP",
        "desc": "JK Lakshmiplast / JK POP superfine gypsum plaster for false ceilings, decorative architectural cornices, and interior surface leveling.",
        "variants": [
            ("JK-POP-1KG",   1.0,  15.0,  25.0,  30.0),
            ("JK-POP-2KG",   2.0,  30.0,  45.0,  55.0),
            ("JK-POP-20KG", 20.0, 155.0, 200.0, 240.0),
            ("JK-POP-25KG", 25.0, 185.0, 235.0, 275.0),
            ("JK-POP-40KG", 40.0, 280.0, 360.0, 410.0),
        ]
    },
]

# Insert products and variants
for p in products_data:
    b_id = brand_ids[p["brand"]]
    s_id = subcat_ids[p["subcat"]]
    
    cursor.execute("""
        INSERT INTO products 
            (name, sku, description, brand_id, category_id, subcategory_id, is_tintable, is_active, created_at, updated_at)
        VALUES (%s, %s, %s, %s, %s, %s, 0, 1, NOW(), NOW())
    """, (p["name"], p["sku"], p["desc"], b_id, CATEGORY_ID, s_id))
    db.commit()
    product_id = cursor.lastrowid
    print(f"\n✅ Product added: {p['name']} (id={product_id}, sku={p['sku']})")

    for (v_sku, pack_size, buy, sell, mrp) in p["variants"]:
        cursor.execute("""
            INSERT INTO product_variants
                (product_id, sku, pack_size, unit_id, purchase_price, selling_price, mrp, is_active, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, 1, NOW(), NOW())
        """, (product_id, v_sku, pack_size, UNIT_KG, buy, sell, mrp))
        db.commit()
        variant_id = cursor.lastrowid

        cursor.execute("""
            INSERT INTO inventory (product_variant_id, quantity)
            VALUES (%s, 0)
        """, (variant_id,))
        db.commit()
        print(f"   ↳ {v_sku} | {int(pack_size)} KG | Buy=₹{buy} Sell=₹{sell} MRP=₹{mrp} (vid={variant_id})")

cursor.close()
db.close()
print("\n🎉 All Birla White & JK White Cement and POP products added successfully!")
