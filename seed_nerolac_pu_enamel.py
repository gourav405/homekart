import mysql.connector

db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Thinksys@123",
    database="homekart"
)
cursor = db.cursor(buffered=True)

# Unit: Litre
cursor.execute("SELECT id FROM units WHERE symbol = 'L'")
unit_l = cursor.fetchone()[0]

# Colors
color_names = ["White", "Base 1", "Base 2", "Base 3", "Black", "Golden Brown", "Smoke Grey", "Signal Red"]
color_ids = {}
for name in color_names:
    cursor.execute("SELECT id FROM colors WHERE name = %s ORDER BY id DESC", (name,))
    row = cursor.fetchone()
    if row:
        color_ids[name] = row[0]
    else:
        cursor.execute("INSERT INTO colors (name, is_active) VALUES (%s, 1)", (name,))
        color_ids[name] = cursor.lastrowid

brand_id = 1 # Nerolac
cat_id = 4   # Enamel
subcat_id = 10 # PU Enamel

products_to_add = [
    # 1. Nerolac PU Enamel 10-in-1 (Bases)
    {
        "name": "Nerolac PU Enamel 10-in-1 (Bases)",
        "sku": "NERO-PU-ENA-BASE",
        "category_id": cat_id,
        "subcategory_id": subcat_id,
        "is_tintable": 1,
        "variants": [
            # White
            ("NER-PU-ENA-WHI-1L", unit_l, 1.0, color_ids["White"], 290.0, 360.0, 430.0),
            ("NER-PU-ENA-WHI-4L", unit_l, 4.0, color_ids["White"], 1100.0, 1360.0, 1630.0),
            ("NER-PU-ENA-WHI-10L", unit_l, 10.0, color_ids["White"], 2650.0, 3250.0, 3900.0),
            ("NER-PU-ENA-WHI-20L", unit_l, 20.0, color_ids["White"], 5100.0, 6300.0, 7500.0),
            # Base 1
            ("NER-PU-ENA-BAS1-1L", unit_l, 1.0, color_ids["Base 1"], 280.0, 350.0, 420.0),
            ("NER-PU-ENA-BAS1-4L", unit_l, 4.0, color_ids["Base 1"], 1060.0, 1320.0, 1580.0),
            ("NER-PU-ENA-BAS1-10L", unit_l, 10.0, color_ids["Base 1"], 2550.0, 3150.0, 3780.0),
            ("NER-PU-ENA-BAS1-20L", unit_l, 20.0, color_ids["Base 1"], 4900.0, 6100.0, 7300.0),
            # Base 2
            ("NER-PU-ENA-BAS2-1L", unit_l, 1.0, color_ids["Base 2"], 270.0, 340.0, 410.0),
            ("NER-PU-ENA-BAS2-4L", unit_l, 4.0, color_ids["Base 2"], 1020.0, 1280.0, 1530.0),
            ("NER-PU-ENA-BAS2-10L", unit_l, 10.0, color_ids["Base 2"], 2450.0, 3050.0, 3660.0),
            ("NER-PU-ENA-BAS2-20L", unit_l, 20.0, color_ids["Base 2"], 4750.0, 5900.0, 7100.0),
            # Base 3
            ("NER-PU-ENA-BAS3-1L", unit_l, 1.0, color_ids["Base 3"], 260.0, 330.0, 395.0),
            ("NER-PU-ENA-BAS3-4L", unit_l, 4.0, color_ids["Base 3"], 980.0, 1230.0, 1475.0),
            ("NER-PU-ENA-BAS3-10L", unit_l, 10.0, color_ids["Base 3"], 2350.0, 2950.0, 3540.0),
            ("NER-PU-ENA-BAS3-20L", unit_l, 20.0, color_ids["Base 3"], 4550.0, 5700.0, 6840.0),
        ]
    },
    # 2. Nerolac PU Enamel 10-in-1 (Pre-Mixed)
    {
        "name": "Nerolac PU Enamel 10-in-1 (Pre-Mixed)",
        "sku": "NERO-PU-ENA-PRE",
        "category_id": cat_id,
        "subcategory_id": subcat_id,
        "is_tintable": 0,
        "variants": [
            # White
            ("NER-PU-ENA-PRE-WHI-500ML", unit_l, 0.5, color_ids["White"], 150.0, 190.0, 225.0),
            ("NER-PU-ENA-PRE-WHI-1L", unit_l, 1.0, color_ids["White"], 280.0, 350.0, 420.0),
            ("NER-PU-ENA-PRE-WHI-4L", unit_l, 4.0, color_ids["White"], 1060.0, 1320.0, 1580.0),
            # Black
            ("NER-PU-ENA-PRE-BLK-500ML", unit_l, 0.5, color_ids["Black"], 150.0, 190.0, 225.0),
            ("NER-PU-ENA-PRE-BLK-1L", unit_l, 1.0, color_ids["Black"], 280.0, 350.0, 420.0),
            ("NER-PU-ENA-PRE-BLK-4L", unit_l, 4.0, color_ids["Black"], 1060.0, 1320.0, 1580.0),
            # Smoke Grey
            ("NER-PU-ENA-PRE-SGR-500ML", unit_l, 0.5, color_ids["Smoke Grey"], 150.0, 190.0, 225.0),
            ("NER-PU-ENA-PRE-SGR-1L", unit_l, 1.0, color_ids["Smoke Grey"], 280.0, 350.0, 420.0),
            ("NER-PU-ENA-PRE-SGR-4L", unit_l, 4.0, color_ids["Smoke Grey"], 1060.0, 1320.0, 1580.0),
            # Golden Brown
            ("NER-PU-ENA-PRE-GBR-500ML", unit_l, 0.5, color_ids["Golden Brown"], 150.0, 190.0, 225.0),
            ("NER-PU-ENA-PRE-GBR-1L", unit_l, 1.0, color_ids["Golden Brown"], 280.0, 350.0, 420.0),
            ("NER-PU-ENA-PRE-GBR-4L", unit_l, 4.0, color_ids["Golden Brown"], 1060.0, 1320.0, 1580.0),
            # Signal Red
            ("NER-PU-ENA-PRE-RED-500ML", unit_l, 0.5, color_ids["Signal Red"], 150.0, 190.0, 225.0),
            ("NER-PU-ENA-PRE-RED-1L", unit_l, 1.0, color_ids["Signal Red"], 280.0, 350.0, 420.0),
            ("NER-PU-ENA-PRE-RED-4L", unit_l, 4.0, color_ids["Signal Red"], 1060.0, 1320.0, 1580.0),
        ]
    }
]

total_products_added = 0
total_variants_added = 0

for p_data in products_to_add:
    cursor.execute("SELECT id FROM products WHERE sku = %s", (p_data["sku"],))
    row = cursor.fetchone()
    if row:
        product_id = row[0]
        print(f"Product '{p_data['name']}' already exists (ID: {product_id})")
    else:
        cursor.execute("""
            INSERT INTO products 
            (name, sku, brand_id, category_id, subcategory_id, is_tintable, is_active)
            VALUES (%s, %s, %s, %s, %s, %s, 1)
        """, (p_data["name"], p_data["sku"], brand_id, p_data["category_id"], p_data["subcategory_id"], p_data["is_tintable"]))
        product_id = cursor.lastrowid
        total_products_added += 1
        print(f"Added product '{p_data['name']}' (ID: {product_id})")

    for v_sku, u_id, pack_size, c_id, pp, sp, mrp in p_data["variants"]:
        cursor.execute("SELECT id FROM product_variants WHERE sku = %s", (v_sku,))
        if cursor.fetchone():
            continue
        cursor.execute("""
            INSERT INTO product_variants
            (product_id, sku, unit_id, pack_size, color_id, purchase_price, selling_price, mrp, is_active)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 1)
        """, (product_id, v_sku, u_id, pack_size, c_id, pp, sp, mrp))
        variant_id = cursor.lastrowid
        cursor.execute("INSERT INTO inventory (product_variant_id, quantity) VALUES (%s, 0)", (variant_id,))
        total_variants_added += 1

db.commit()
cursor.close()
db.close()
print(f"\nDone! Added {total_products_added} products and {total_variants_added} variants.")
