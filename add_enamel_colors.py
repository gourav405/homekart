#!/usr/bin/env python3
"""
Add 3 new Nerolac Synthetic Enamel (Pre-Mixed) shades:
  - Bus Green
  - Pherozi (Ferozi / Turquoise)
  - Oxford Blue
Each gets 3 pack sizes: 500ml, 1L, 4L
Same pricing as existing pre-mixed enamel shades.
Product: Nerolac Synthetic Enamel (Pre-Mixed) → product_id = 38
"""

import mysql.connector

db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Thinksys@123",
    database="homekart"
)
cursor = db.cursor(buffered=True)

PRODUCT_ID = 38   # Nerolac Synthetic Enamel (Pre-Mixed)
UNIT_ID = 1       # Litre

# -------------------------------------------------------------------
# Step 1: Insert 3 new colors
# -------------------------------------------------------------------
new_colors = [
    ("Bus Green",  "BUS-GRN", "#1A6B2A"),
    ("Pherozi",    "PHRZ",    "#00BCD4"),
    ("Oxford Blue","OXF-BLU", "#002147"),
]

color_ids = {}
for (name, code, hex_code) in new_colors:
    cursor.execute("""
        INSERT INTO colors (name, code, hex_code, is_active)
        VALUES (%s, %s, %s, 1)
    """, (name, code, hex_code))
    db.commit()
    cid = cursor.lastrowid
    color_ids[name] = cid
    print(f"✅ Color added: {name} (id={cid}, code={code}, hex={hex_code})")

# -------------------------------------------------------------------
# Step 2: Add 3 variants per color (500ml, 1L, 4L)
# Pricing matches existing pre-mixed enamel shades
# -------------------------------------------------------------------
variants = [
    # (sku_code, pack_size, purchase, selling, mrp)
    ("BGN",  "BUS-GRN", 0.50, 120.0, 150.0, 180.0),
    ("BGN",  "BUS-GRN", 1.00, 220.0, 280.0, 335.0),
    ("BGN",  "BUS-GRN", 4.00, 900.0, 1100.0, 1320.0),
    ("PHR",  "PHRZ",    0.50, 120.0, 150.0, 180.0),
    ("PHR",  "PHRZ",    1.00, 220.0, 280.0, 335.0),
    ("PHR",  "PHRZ",    4.00, 900.0, 1100.0, 1320.0),
    ("OBL",  "OXF-BLU", 0.50, 120.0, 150.0, 180.0),
    ("OBL",  "OXF-BLU", 1.00, 220.0, 280.0, 335.0),
    ("OBL",  "OXF-BLU", 4.00, 900.0, 1100.0, 1320.0),
]

# Map color short code → color name for lookup
code_to_name = {
    "BUS-GRN": "Bus Green",
    "PHRZ":    "Pherozi",
    "OXF-BLU": "Oxford Blue",
}

pack_label = {0.50: "500ML", 1.00: "1L", 4.00: "4L"}

print()
for (sku_prefix, color_code, pack_size, purchase, selling, mrp) in variants:
    color_name = code_to_name[color_code]
    cid = color_ids[color_name]
    sku = f"NER-ENA-PRE-{sku_prefix}-{pack_label[pack_size]}"

    cursor.execute("""
        INSERT INTO product_variants
            (product_id, sku, color_id, pack_size, unit_id,
             purchase_price, selling_price, mrp,
             is_active, created_at, updated_at)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 1, NOW(), NOW())
    """, (PRODUCT_ID, sku, cid, pack_size, UNIT_ID, purchase, selling, mrp))
    db.commit()
    variant_id = cursor.lastrowid

    cursor.execute("""
        INSERT INTO inventory (product_variant_id, quantity) VALUES (%s, 0)
    """, (variant_id,))
    db.commit()
    print(f"   ↳ {sku} | {pack_size}L | Buy={purchase} Sell={selling} MRP={mrp} | vid={variant_id}")

print("\n🎉 Bus Green, Pherozi, Oxford Blue added successfully!")
cursor.close()
db.close()
