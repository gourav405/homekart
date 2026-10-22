import mysql.connector

db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Thinksys@123",
    database="homekart"
)
cursor = db.cursor(buffered=True)

# 1. Colors to insert/fetch
new_colors = [
    ("PO Red", "PORED", "#D00000"),
    ("Golden Yellow", "GYLW", "#FFDF00"),
    ("Middle Buff", "MBUF", "#DAA520"),
    ("Crimson", "CRMS", "#DC143C"),
]

color_ids = {}
for name, code, hex_c in new_colors:
    cursor.execute("SELECT id FROM colors WHERE name = %s", (name,))
    row = cursor.fetchone()
    if row:
        color_ids[name] = row[0]
        print(f"Color '{name}' exists (ID: {row[0]})")
    else:
        cursor.execute("INSERT INTO colors (name, code, hex_code, is_active) VALUES (%s, %s, %s, 1)", (name, code, hex_c))
        color_ids[name] = cursor.lastrowid
        print(f"Added color '{name}' (ID: {color_ids[name]})")

# 2. Get Product: Nerolac Synthetic Enamel (Pre-Mixed)
cursor.execute("SELECT id FROM products WHERE sku = 'NERO-ENA-PRE'")
product_row = cursor.fetchone()
if not product_row:
    print("Error: Product NERO-ENA-PRE not found!")
    exit(1)

product_id = product_row[0]

# 3. Unit: Litre
cursor.execute("SELECT id FROM units WHERE symbol = 'L'")
unit_l = cursor.fetchone()[0]

# 4. Variants for the 4 shades across 500 mL, 1 L, 4 L
variants = [
    # PO Red
    ("NER-ENA-PRE-POR-500ML", unit_l, 0.5, color_ids["PO Red"], 120.0, 150.0, 180.0),
    ("NER-ENA-PRE-POR-1L", unit_l, 1.0, color_ids["PO Red"], 220.0, 280.0, 335.0),
    ("NER-ENA-PRE-POR-4L", unit_l, 4.0, color_ids["PO Red"], 900.0, 1100.0, 1320.0),

    # Golden Yellow
    ("NER-ENA-PRE-GYL-500ML", unit_l, 0.5, color_ids["Golden Yellow"], 120.0, 150.0, 180.0),
    ("NER-ENA-PRE-GYL-1L", unit_l, 1.0, color_ids["Golden Yellow"], 220.0, 280.0, 335.0),
    ("NER-ENA-PRE-GYL-4L", unit_l, 4.0, color_ids["Golden Yellow"], 900.0, 1100.0, 1320.0),

    # Middle Buff
    ("NER-ENA-PRE-MBF-500ML", unit_l, 0.5, color_ids["Middle Buff"], 120.0, 150.0, 180.0),
    ("NER-ENA-PRE-MBF-1L", unit_l, 1.0, color_ids["Middle Buff"], 220.0, 280.0, 335.0),
    ("NER-ENA-PRE-MBF-4L", unit_l, 4.0, color_ids["Middle Buff"], 900.0, 1100.0, 1320.0),

    # Crimson
    ("NER-ENA-PRE-CRM-500ML", unit_l, 0.5, color_ids["Crimson"], 120.0, 150.0, 180.0),
    ("NER-ENA-PRE-CRM-1L", unit_l, 1.0, color_ids["Crimson"], 220.0, 280.0, 335.0),
    ("NER-ENA-PRE-CRM-4L", unit_l, 4.0, color_ids["Crimson"], 900.0, 1100.0, 1320.0),
]

added_count = 0
for v_sku, u_id, pack_size, c_id, pp, sp, mrp in variants:
    cursor.execute("SELECT id FROM product_variants WHERE sku = %s", (v_sku,))
    if cursor.fetchone():
        print(f"Variant {v_sku} already exists, skipping.")
        continue
    cursor.execute("""
        INSERT INTO product_variants
        (product_id, sku, unit_id, pack_size, color_id, purchase_price, selling_price, mrp, is_active)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 1)
    """, (product_id, v_sku, u_id, pack_size, c_id, pp, sp, mrp))
    variant_id = cursor.lastrowid
    cursor.execute("INSERT INTO inventory (product_variant_id, quantity) VALUES (%s, 0)", (variant_id,))
    added_count += 1
    print(f"Added variant {v_sku} (ID: {variant_id})")

db.commit()
cursor.close()
db.close()
print(f"\nSuccessfully added {added_count} variants for PO Red, Golden Yellow, Middle Buff, and Crimson!")
