#!/usr/bin/env python3
"""
Add Dr. Fixit Roofseal Classic to homekart DB:
Brand: Dr. Fixit (Pidilite)
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

CATEGORY_ID = 8      # Waterproofing
SUBCATEGORY_ID = 23  # Roof Waterproofing
UNIT_L = 1           # Litre
WHITE_COLOR_ID = 38  # White

# 1. Brand: Dr. Fixit
cursor.execute("SELECT id FROM brands WHERE name = 'Dr. Fixit'")
row = cursor.fetchone()
if row:
    brand_id = row[0]
else:
    cursor.execute("""
        INSERT INTO brands (name, description, is_active, created_at, updated_at)
        VALUES ('Dr. Fixit', 'Dr. Fixit (Pidilite Industries)', 1, NOW(), NOW())
    """)
    db.commit()
    brand_id = cursor.lastrowid
print(f"Brand: Dr. Fixit -> id={brand_id}")

# 2. Product
product_name = "Dr. Fixit Roofseal Classic"
product_sku = "DRF-ROOFSEAL-CLS"
product_desc = "Elastomeric waterproof and heat-reducing acrylic coating for roofs, terraces, parapets, and sloped exterior surfaces."

cursor.execute("""
    INSERT INTO products
        (name, sku, description, brand_id, category_id, subcategory_id, is_tintable, is_active, created_at, updated_at)
    VALUES (%s, %s, %s, %s, %s, %s, 0, 1, NOW(), NOW())
""", (product_name, product_sku, product_desc, brand_id, CATEGORY_ID, SUBCATEGORY_ID))
db.commit()
product_id = cursor.lastrowid
print(f"✅ Product added: {product_name} (id={product_id}, sku={product_sku})")

# 3. Variants
variants = [
    # (sku, pack_size, buy, sell, mrp)
    ("DRF-RFSL-1L",   1.0,   340.0,   420.0,   480.0),
    ("DRF-RFSL-4L",   4.0,  1250.0,  1550.0,  1800.0),
    ("DRF-RFSL-10L", 10.0,  2900.0,  3500.0,  4100.0),
    ("DRF-RFSL-20L", 20.0,  5200.0,  6300.0,  7400.0),
]

for (v_sku, pack_size, buy, sell, mrp) in variants:
    cursor.execute("""
        INSERT INTO product_variants
            (product_id, sku, color_id, pack_size, unit_id, purchase_price, selling_price, mrp, is_active, created_at, updated_at)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 1, NOW(), NOW())
    """, (product_id, v_sku, WHITE_COLOR_ID, pack_size, UNIT_L, buy, sell, mrp))
    db.commit()
    variant_id = cursor.lastrowid

    # 4. Inventory
    cursor.execute("""
        INSERT INTO inventory (product_variant_id, quantity)
        VALUES (%s, 0)
    """, (variant_id,))
    db.commit()
    print(f"   ↳ {v_sku} | {int(pack_size)}L | Buy=₹{buy} Sell=₹{sell} MRP=₹{mrp} (vid={variant_id})")

cursor.close()
db.close()
print("\n🎉 Dr. Fixit Roofseal Classic added successfully!")
