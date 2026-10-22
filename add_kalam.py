#!/usr/bin/env python3
"""
Add single Kalam (Round Paint Brush) to homekart DB:
Category: Brushes (category_id = 9)
Subcategory: Kalam (Round Brush)
Brand: Star (brand_id = 3)
Product: Star Paint Kalam (Round Brush)
Variant: Standard (Per Piece)
"""

import mysql.connector

db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Thinksys@123",
    database="homekart"
)
cursor = db.cursor(buffered=True, dictionary=True)

CATEGORY_ID = 9   # Brushes
BRAND_ID = 3      # Star
UNIT_PCS = 5      # Piece

# 1. Check or create Subcategory
cursor.execute("SELECT id FROM subcategories WHERE category_id = %s AND (name LIKE '%Kalam%' OR name LIKE '%Round%')", (CATEGORY_ID,))
row = cursor.fetchone()
if row:
    subcat_id = row["id"]
    print(f"Found existing subcategory id={subcat_id}")
else:
    cursor.execute("""
        INSERT INTO subcategories (name, category_id, is_active, created_at, updated_at)
        VALUES ('Kalam (Round Brush)', %s, 1, NOW(), NOW())
    """, (CATEGORY_ID,))
    db.commit()
    subcat_id = cursor.lastrowid
    print(f"Created subcategory 'Kalam (Round Brush)' id={subcat_id}")

# 2. Check if product already exists
cursor.execute("SELECT id FROM products WHERE sku = 'STAR-KALAM'")
row = cursor.fetchone()
if row:
    product_id = row["id"]
    print(f"Product STAR-KALAM already exists (id={product_id})")
else:
    cursor.execute("""
        INSERT INTO products 
            (name, sku, description, brand_id, category_id, subcategory_id, hsn_code, is_tintable, is_active, created_at, updated_at)
        VALUES 
            (%s, %s, %s, %s, %s, %s, '9603', 0, 1, NOW(), NOW())
    """, (
        "Star Paint Kalam (Round Brush)",
        "STAR-KALAM",
        "Round touch-up & corner paint brush (Kalam) for painting cutting-in, window grills, corners, pipes, and small spaces.",
        BRAND_ID,
        CATEGORY_ID,
        subcat_id
    ))
    db.commit()
    product_id = cursor.lastrowid
    print(f"✅ Product created: Star Paint Kalam (Round Brush) (id={product_id})")

# 3. Check or insert single variant
cursor.execute("SELECT id FROM product_variants WHERE sku = 'STAR-KALAM-STD'")
vrow = cursor.fetchone()
if vrow:
    variant_id = vrow["id"]
    print(f"Variant STAR-KALAM-STD already exists (id={variant_id})")
else:
    cursor.execute("""
        INSERT INTO product_variants
            (product_id, sku, variant_name, pack_size, unit_id, purchase_price, selling_price, mrp, is_active, created_at, updated_at)
        VALUES 
            (%s, 'STAR-KALAM-STD', 'Standard (Per Piece)', 1.0, %s, 15.00, 25.00, 30.00, 1, NOW(), NOW())
    """, (product_id, UNIT_PCS))
    db.commit()
    variant_id = cursor.lastrowid
    print(f"✅ Variant created: Standard (Per Piece) (id={variant_id}, Buy=₹15, Sell=₹25, MRP=₹30)")

    # 4. Insert inventory
    cursor.execute("""
        INSERT INTO inventory (product_variant_id, quantity, minimum_stock, maximum_stock)
        VALUES (%s, 25, 10, 100)
    """, (variant_id,))
    db.commit()
    print(f"✅ Inventory initialized: 25 PCS")

cursor.close()
db.close()
print("\n🎉 Single Kalam product added successfully!")
