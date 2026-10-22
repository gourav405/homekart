#!/usr/bin/env python3
"""
Add Sandpaper & Abrasives products to homekart DB:
Category: Sandpaper & Abrasives (category_id = 11)
Subcategories:
- 34: Waterproof Sheet Sandpaper
- 35: Disc Sandpaper / Sanding Disc
- 36: Emery Cloth Roll
Brand: Champion (Abrasives)
"""

import mysql.connector

db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Thinksys@123",
    database="homekart"
)
cursor = db.cursor(buffered=True)

CATEGORY_ID = 11  # Sandpaper & Abrasives
SUBCAT_SHEET = 34
SUBCAT_DISC  = 35
SUBCAT_ROLL  = 36

UNIT_PCS = 5      # Piece
UNIT_MTR = 6      # Meter

# 1. Brand: Champion
cursor.execute("SELECT id FROM brands WHERE name = 'Champion'")
row = cursor.fetchone()
if row:
    brand_id = row[0]
else:
    cursor.execute("""
        INSERT INTO brands (name, description, is_active, created_at, updated_at)
        VALUES ('Champion', 'Champion Abrasives & Sandpaper', 1, NOW(), NOW())
    """)
    db.commit()
    brand_id = cursor.lastrowid
print(f"Brand: Champion -> id={brand_id}")

# 2. Products & Variants Data
products_data = [
    # ── Waterproof Sheet Sandpaper (Water Paper) ──
    {
        "name": "Champion Waterproof Sandpaper (Sheet)",
        "sku": "CHAMP-SANDPAPER-SHT",
        "subcat": SUBCAT_SHEET,
        "unit": UNIT_PCS,
        "description": "Silicon carbide waterproof wet & dry abrasive sheets (9x11 inch) for wall putty, plaster, primers, wood, and metal sanding.",
        "variants": [
            # (sku, variant_name, buy, sell, mrp)
            ("CHAMP-SP-SHT-80",  "Grit 80",   7.0, 12.0, 15.0),
            ("CHAMP-SP-SHT-100", "Grit 100",  7.0, 12.0, 15.0),
            ("CHAMP-SP-SHT-120", "Grit 120",  7.0, 12.0, 15.0),
            ("CHAMP-SP-SHT-150", "Grit 150",  7.0, 12.0, 15.0),
            ("CHAMP-SP-SHT-180", "Grit 180",  7.0, 12.0, 15.0),
            ("CHAMP-SP-SHT-220", "Grit 220",  7.0, 12.0, 15.0),
            ("CHAMP-SP-SHT-320", "Grit 320",  8.0, 15.0, 20.0),
            ("CHAMP-SP-SHT-400", "Grit 400",  8.0, 15.0, 20.0),
        ]
    },
    # ── Machine Sanding Disc (Velcro / Hook-and-Loop) ──
    {
        "name": "Champion Machine Sanding Disc (Velcro)",
        "sku": "CHAMP-SANDING-DISC",
        "subcat": SUBCAT_DISC,
        "unit": UNIT_PCS,
        "description": "Hook-and-loop perforated circular sanding discs for wall sanding machines and rotary drywall sanders.",
        "variants": [
            ("CHAMP-DISC-9IN-80",  "9 Inch - Grit 80",  15.0, 25.0, 35.0),
            ("CHAMP-DISC-9IN-120", "9 Inch - Grit 120", 15.0, 25.0, 35.0),
            ("CHAMP-DISC-9IN-150", "9 Inch - Grit 150", 15.0, 25.0, 35.0),
            ("CHAMP-DISC-9IN-180", "9 Inch - Grit 180", 15.0, 25.0, 35.0),
            ("CHAMP-DISC-9IN-240", "9 Inch - Grit 240", 16.0, 30.0, 40.0),
            ("CHAMP-DISC-7IN-80",  "7 Inch - Grit 80",  12.0, 20.0, 30.0),
            ("CHAMP-DISC-7IN-120", "7 Inch - Grit 120", 12.0, 20.0, 30.0),
            ("CHAMP-DISC-7IN-180", "7 Inch - Grit 180", 12.0, 20.0, 30.0),
        ]
    },
    # ── Red Emery Cloth Roll ──
    {
        "name": "Champion Red Emery Cloth Roll",
        "sku": "CHAMP-EMERY-ROLL",
        "subcat": SUBCAT_ROLL,
        "unit": UNIT_MTR,
        "description": "4-inch wide heavy duty red emery cloth abrasive roll for rust removal, metal polishing, hard wood, and rough wall preparation.",
        "variants": [
            ("CHAMP-EMERY-60-MTR",  "Grit 60 (Per Meter)",  25.0, 45.0, 55.0),
            ("CHAMP-EMERY-80-MTR",  "Grit 80 (Per Meter)",  25.0, 45.0, 55.0),
            ("CHAMP-EMERY-100-MTR", "Grit 100 (Per Meter)", 25.0, 45.0, 55.0),
            ("CHAMP-EMERY-120-MTR", "Grit 120 (Per Meter)", 25.0, 45.0, 55.0),
            ("CHAMP-EMERY-150-MTR", "Grit 150 (Per Meter)", 25.0, 45.0, 55.0),
        ]
    }
]

for p in products_data:
    # 1. Insert product
    cursor.execute("""
        INSERT INTO products 
            (name, sku, description, brand_id, category_id, subcategory_id, is_tintable, is_active, created_at, updated_at)
        VALUES (%s, %s, %s, %s, %s, %s, 0, 1, NOW(), NOW())
    """, (p["name"], p["sku"], p["description"], brand_id, CATEGORY_ID, p["subcat"]))
    db.commit()
    product_id = cursor.lastrowid
    print(f"\n✅ Product added: {p['name']} (id={product_id}, sku={p['sku']})")

    # 2. Insert variants
    for (v_sku, v_name, buy, sell, mrp) in p["variants"]:
        cursor.execute("""
            INSERT INTO product_variants
                (product_id, sku, variant_name, pack_size, unit_id, purchase_price, selling_price, mrp, is_active, created_at, updated_at)
            VALUES (%s, %s, %s, 1.0, %s, %s, %s, %s, 1, NOW(), NOW())
        """, (product_id, v_sku, v_name, p["unit"], buy, sell, mrp))
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
print("\n🎉 All Sandpaper, Discs, and Emery Roll products added successfully!")
