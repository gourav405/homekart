import mysql.connector

db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Thinksys@123",
    database="homekart"
)
cursor = db.cursor(buffered=True)

# Get Units
cursor.execute("SELECT id, symbol FROM units")
units = {row[1]: row[0] for row in cursor.fetchall()}
u_l = units['L']
u_kg = units['KG']

# Get / Insert Colors
colors_needed = [
    ("White", "WHI", "#FFFFFF"),
    ("Red Oxide", "ROX", "#800000"),
    ("Pink", "PNK", "#FFC0CB"),
    ("Black", "BLK", "#000000"),
    ("Golden Brown", "GBR", "#996515"),
    ("Smoke Grey", "SGR", "#708090"),
    ("Coffee Brown", "CBR", "#4B3621"),
    ("Signal Red", "SRED", "#FF0000"),
    ("Base 1", "BAS1", "#F5F5DC"),
    ("Base 2", "BAS2", "#D2B48C"),
    ("Base 3", "BAS3", "#8B7355"),
]

color_ids = {}
for name, code, hex_c in colors_needed:
    cursor.execute("SELECT id FROM colors WHERE name = %s", (name,))
    row = cursor.fetchone()
    if row:
        color_ids[name] = row[0]
    else:
        cursor.execute("INSERT INTO colors (name, code, hex_code, is_active) VALUES (%s, %s, %s, 1)", (name, code, hex_c))
        color_ids[name] = cursor.lastrowid

brand_id = 1 # Nerolac

products_to_add = [
    # 1. Nerolac Cement Primer (WT)
    {
        "name": "Nerolac Cement Primer (WT)",
        "sku": "NERO-PRM-WT",
        "category_id": 6, # Primers
        "subcategory_id": 14, # Interior Wall Primer
        "is_tintable": 0,
        "variants": [
            ("NER-PRM-WT-1L", u_l, 1.0, color_ids["White"], 110.0, 140.0, 170.0),
            ("NER-PRM-WT-4L", u_l, 4.0, color_ids["White"], 420.0, 520.0, 620.0),
            ("NER-PRM-WT-10L", u_l, 10.0, color_ids["White"], 1000.0, 1250.0, 1500.0),
            ("NER-PRM-WT-20L", u_l, 20.0, color_ids["White"], 1900.0, 2400.0, 2900.0),
        ]
    },
    # 2. Nerolac Red Oxide Metal Primer
    {
        "name": "Nerolac Red Oxide Metal Primer",
        "sku": "NERO-RO-PRM",
        "category_id": 6, # Primers
        "subcategory_id": 16, # Metal Primer (Red Oxide)
        "is_tintable": 0,
        "variants": [
            ("NER-RO-PRM-500ML", u_l, 0.5, color_ids["Red Oxide"], 75.0, 95.0, 115.0),
            ("NER-RO-PRM-1L", u_l, 1.0, color_ids["Red Oxide"], 140.0, 175.0, 210.0),
            ("NER-RO-PRM-4L", u_l, 4.0, color_ids["Red Oxide"], 530.0, 670.0, 800.0),
            ("NER-RO-PRM-20L", u_l, 20.0, color_ids["Red Oxide"], 2500.0, 3200.0, 3800.0),
        ]
    },
    # 3. Nerolac Wood Primer
    {
        "name": "Nerolac Wood Primer",
        "sku": "NERO-PR-WOOD",
        "category_id": 6, # Primers
        "subcategory_id": 17, # Wood Primer
        "is_tintable": 0,
        "variants": [
            ("NER-PR-WOOD-500ML", u_l, 0.5, color_ids["White"], 85.0, 110.0, 135.0),
            ("NER-PR-WOOD-1L", u_l, 1.0, color_ids["White"], 165.0, 210.0, 250.0),
            ("NER-PR-WOOD-4L", u_l, 4.0, color_ids["White"], 650.0, 820.0, 980.0),
        ]
    },
    # 4. Nerolac Synthetic Enamel (Bases)
    {
        "name": "Nerolac Synthetic Enamel (Bases)",
        "sku": "NERO-ENA-BASE",
        "category_id": 4, # Enamel
        "subcategory_id": 9, # Synthetic Enamel
        "is_tintable": 1,
        "variants": [
            ("NER-ENA-BAS1-1L", u_l, 1.0, color_ids["Base 1"], 190.0, 250.0, 300.0),
            ("NER-ENA-BAS1-4L", u_l, 4.0, color_ids["Base 1"], 740.0, 960.0, 1150.0),
            ("NER-ENA-BAS1-10L", u_l, 10.0, color_ids["Base 1"], 1800.0, 2350.0, 2800.0),
            ("NER-ENA-BAS1-20L", u_l, 20.0, color_ids["Base 1"], 3500.0, 4500.0, 5400.0),
            ("NER-ENA-BAS2-1L", u_l, 1.0, color_ids["Base 2"], 185.0, 240.0, 290.0),
            ("NER-ENA-BAS2-4L", u_l, 4.0, color_ids["Base 2"], 720.0, 930.0, 1120.0),
            ("NER-ENA-BAS2-10L", u_l, 10.0, color_ids["Base 2"], 1750.0, 2280.0, 2700.0),
            ("NER-ENA-BAS2-20L", u_l, 20.0, color_ids["Base 2"], 3400.0, 4400.0, 5300.0),
            ("NER-ENA-BAS3-1L", u_l, 1.0, color_ids["Base 3"], 180.0, 230.0, 280.0),
            ("NER-ENA-BAS3-4L", u_l, 4.0, color_ids["Base 3"], 700.0, 900.0, 1080.0),
            ("NER-ENA-BAS3-10L", u_l, 10.0, color_ids["Base 3"], 1700.0, 2200.0, 2600.0),
            ("NER-ENA-BAS3-20L", u_l, 20.0, color_ids["Base 3"], 3300.0, 4300.0, 5100.0),
            ("NER-ENA-WHI-1L", u_l, 1.0, color_ids["White"], 200.0, 260.0, 310.0),
            ("NER-ENA-WHI-4L", u_l, 4.0, color_ids["White"], 780.0, 1000.0, 1200.0),
            ("NER-ENA-WHI-10L", u_l, 10.0, color_ids["White"], 1900.0, 2450.0, 2950.0),
            ("NER-ENA-WHI-20L", u_l, 20.0, color_ids["White"], 3700.0, 4700.0, 5600.0),
        ]
    },
    # 5. Nerolac Synthetic Enamel (Pre-Mixed)
    {
        "name": "Nerolac Synthetic Enamel (Pre-Mixed)",
        "sku": "NERO-ENA-PRE",
        "category_id": 4, # Enamel
        "subcategory_id": 9, # Synthetic Enamel
        "is_tintable": 0,
        "variants": [
            ("NER-ENA-PRE-BLK-500ML", u_l, 0.5, color_ids["Black"], 120.0, 150.0, 180.0),
            ("NER-ENA-PRE-BLK-1L", u_l, 1.0, color_ids["Black"], 220.0, 280.0, 335.0),
            ("NER-ENA-PRE-BLK-4L", u_l, 4.0, color_ids["Black"], 900.0, 1100.0, 1320.0),
            ("NER-ENA-PRE-GBR-500ML", u_l, 0.5, color_ids["Golden Brown"], 120.0, 150.0, 180.0),
            ("NER-ENA-PRE-GBR-1L", u_l, 1.0, color_ids["Golden Brown"], 220.0, 280.0, 335.0),
            ("NER-ENA-PRE-GBR-4L", u_l, 4.0, color_ids["Golden Brown"], 900.0, 1100.0, 1320.0),
            ("NER-ENA-PRE-SGR-500ML", u_l, 0.5, color_ids["Smoke Grey"], 120.0, 150.0, 180.0),
            ("NER-ENA-PRE-SGR-1L", u_l, 1.0, color_ids["Smoke Grey"], 220.0, 280.0, 335.0),
            ("NER-ENA-PRE-SGR-4L", u_l, 4.0, color_ids["Smoke Grey"], 900.0, 1100.0, 1320.0),
            ("NER-ENA-PRE-CBR-500ML", u_l, 0.5, color_ids["Coffee Brown"], 120.0, 150.0, 180.0),
            ("NER-ENA-PRE-CBR-1L", u_l, 1.0, color_ids["Coffee Brown"], 220.0, 280.0, 335.0),
            ("NER-ENA-PRE-CBR-4L", u_l, 4.0, color_ids["Coffee Brown"], 900.0, 1100.0, 1320.0),
            ("NER-ENA-PRE-WHI-500ML", u_l, 0.5, color_ids["White"], 120.0, 150.0, 180.0),
            ("NER-ENA-PRE-WHI-1L", u_l, 1.0, color_ids["White"], 220.0, 280.0, 335.0),
            ("NER-ENA-PRE-WHI-4L", u_l, 4.0, color_ids["White"], 900.0, 1100.0, 1320.0),
            ("NER-ENA-PRE-RED-500ML", u_l, 0.5, color_ids["Signal Red"], 120.0, 150.0, 180.0),
            ("NER-ENA-PRE-RED-1L", u_l, 1.0, color_ids["Signal Red"], 220.0, 280.0, 335.0),
            ("NER-ENA-PRE-RED-4L", u_l, 4.0, color_ids["Signal Red"], 900.0, 1100.0, 1320.0),
        ]
    },
    # 6. Nerolac Premium Synthetic Enamel
    {
        "name": "Nerolac Premium Synthetic Enamel",
        "sku": "NERO-PREM-ENA",
        "category_id": 4, # Enamel
        "subcategory_id": 11, # Satin / Gloss Enamel
        "is_tintable": 0,
        "variants": [
            ("NER-PREM-ENA-500ML", u_l, 0.5, color_ids["White"], 140.0, 170.0, 205.0),
            ("NER-PREM-ENA-1L", u_l, 1.0, color_ids["White"], 270.0, 330.0, 395.0),
            ("NER-PREM-ENA-4L", u_l, 4.0, color_ids["White"], 1020.0, 1250.0, 1500.0),
            ("NER-PREM-ENA-20L", u_l, 20.0, color_ids["White"], 4900.0, 6000.0, 7200.0),
        ]
    },
    # 7. Nerolac Beauty Acrylic Distemper
    {
        "name": "Nerolac Beauty Acrylic Distemper",
        "sku": "NERO-BEAU-DIST",
        "category_id": 5, # Distemper
        "subcategory_id": 12, # Acrylic Distemper
        "is_tintable": 1,
        "variants": [
            ("NER-DIST-2KG", u_kg, 2.0, color_ids["White"], 90.0, 110.0, 130.0),
            ("NER-DIST-5KG", u_kg, 5.0, color_ids["White"], 200.0, 250.0, 300.0),
            ("NER-DIST-10KG", u_kg, 10.0, color_ids["White"], 380.0, 480.0, 570.0),
            ("NER-DIST-20KG", u_kg, 20.0, color_ids["White"], 720.0, 900.0, 1080.0),
        ]
    },
    # 8. Nerolac Perma Damp Proof
    {
        "name": "Nerolac Perma Damp Proof",
        "sku": "NERO-PERMA-DAMP",
        "category_id": 8, # Waterproofing
        "subcategory_id": 24, # Wall Waterproofing / Damp Proof
        "is_tintable": 0,
        "variants": [
            ("NER-DAMP-1L", u_l, 1.0, color_ids["White"], 260.0, 320.0, 380.0),
            ("NER-DAMP-4L", u_l, 4.0, color_ids["White"], 980.0, 1200.0, 1440.0),
            ("NER-DAMP-10L", u_l, 10.0, color_ids["White"], 2400.0, 2900.0, 3480.0),
            ("NER-DAMP-20L", u_l, 20.0, color_ids["White"], 4600.0, 5600.0, 6700.0),
        ]
    },
    # 9. Nerolac General Purpose Thinner
    {
        "name": "Nerolac General Purpose Thinner",
        "sku": "NERO-THIN-GP",
        "category_id": 12, # Thinners & Solvents
        "subcategory_id": 37, # General Purpose Thinner
        "is_tintable": 0,
        "variants": [
            ("NER-THIN-GP-500ML", u_l, 0.5, None, 45.0, 60.0, 75.0),
            ("NER-THIN-GP-1L", u_l, 1.0, None, 80.0, 110.0, 135.0),
            ("NER-THIN-GP-4L", u_l, 4.0, None, 300.0, 420.0, 500.0),
        ]
    },
    # 10. Nerolac PU Thinner
    {
        "name": "Nerolac PU Thinner",
        "sku": "NERO-THIN-PU",
        "category_id": 12, # Thinners & Solvents
        "subcategory_id": 38, # PU Thinner
        "is_tintable": 0,
        "variants": [
            ("NER-THIN-PU-1L", u_l, 1.0, None, 150.0, 190.0, 230.0),
            ("NER-THIN-PU-4L", u_l, 4.0, None, 580.0, 720.0, 860.0),
        ]
    },
]

total_products_added = 0
total_variants_added = 0

for p_data in products_to_add:
    # Check if product already exists
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

    for v_sku, unit_id, pack_size, color_id, pp, sp, mrp in p_data["variants"]:
        cursor.execute("SELECT id FROM product_variants WHERE sku = %s", (v_sku,))
        if cursor.fetchone():
            continue
        cursor.execute("""
            INSERT INTO product_variants
            (product_id, sku, unit_id, pack_size, color_id, purchase_price, selling_price, mrp, is_active)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 1)
        """, (product_id, v_sku, unit_id, pack_size, color_id, pp, sp, mrp))
        variant_id = cursor.lastrowid
        cursor.execute("INSERT INTO inventory (product_variant_id, quantity) VALUES (%s, 0)", (variant_id,))
        total_variants_added += 1

db.commit()
cursor.close()
db.close()
print(f"\nCompleted! Added {total_products_added} products and {total_variants_added} variants.")
