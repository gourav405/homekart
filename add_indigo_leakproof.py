#!/usr/bin/env python3
"""
Add Indigo Leakproof to homekart DB:
Brand: Indigo (brand_id = 2)
Category: Waterproofing (category_id = 8)
Subcategory: Roof Waterproofing (subcategory_id = 23)
Pack sizes: 1L, 4L, 10L, 20L
Color: White (id = 38)
Unit: Litre (unit_id = 1)
"""

import mysql.connector

db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Thinksys@123",
    database="homekart"
)
cursor = db.cursor(buffered=True)

BRAND_ID = 2         # Indigo
CATEGORY_ID = 8      # Waterproofing
SUBCATEGORY_ID = 23  # Roof Waterproofing
UNIT_L = 1           # Litre
WHITE_COLOR_ID = 38  # White

product_name = "Indigo Leakproof Emulsion"
product_sku = "IND-LEAKPROOF"
product_desc = "Micro-fibre reinforced 2-in-1 elastomeric waterproof and heat-reflective coating for terraces, roofs, and vertical exterior walls."

# 1. Product
cursor.execute("""
    INSERT INTO products
        (name, sku, description, brand_id, category_id, subcategory_id, is_tintable, is_active, created_at, updated_at)
    VALUES (%s, %s, %s, %s, %s, %s, 0, 1, NOW(), NOW())
""", (product_name, product_sku, product_desc, BRAND_ID, CATEGORY_ID, SUBCATEGORY_ID))
db.commit()
product_id = cursor.lastrowid
print(f"✅ Product added: {product_name} (id={product_id}, sku={product_sku})")

# 2. Variants
variants = [
    # (sku, pack_size, buy, sell, mrp)
    ("IND-LEAKPROOF-1L",   1.0,   320.0,   400.0,   460.0),
    ("IND-LEAKPROOF-4L",   4.0,  1180.0,  1450.0,  1680.0),
    ("IND-LEAKPROOF-10L", 10.0,  2800.0,  3400.0,  3950.0),
    ("IND-LEAKPROOF-20L", 20.0,  5300.0,  6400.0,  7450.0),
]

for (v_sku, pack_size, buy, sell, mrp) in variants:
    cursor.execute("""
        INSERT INTO product_variants
            (product_id, sku, color_id, pack_size, unit_id, purchase_price, selling_price, mrp, is_active, created_at, updated_at)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 1, NOW(), NOW())
    """, (product_id, v_sku, WHITE_COLOR_ID, pack_size, UNIT_L, buy, sell, mrp))
    db.commit()
    variant_id = cursor.lastrowid

    # 3. Inventory
    cursor.execute("""
        INSERT INTO inventory (product_variant_id, quantity)
        VALUES (%s, 0)
    """, (variant_id,))
    db.commit()
    print(f"   ↳ {v_sku} | {int(pack_size)}L | Buy=₹{buy} Sell=₹{sell} MRP=₹{mrp} (vid={variant_id})")

cursor.close()
db.close()
print("\n🎉 Indigo Leakproof added successfully!")
