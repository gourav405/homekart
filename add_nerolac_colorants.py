#!/usr/bin/env python3
"""
1. Set all existing and new products in homekart to is_tax_inclusive = 1
2. Add the 14 Nerolac Machine Colorants (1 Litre bottles) to homekart DB
"""

import mysql.connector

db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Thinksys@123",
    database="homekart"
)
cursor = db.cursor(buffered=True, dictionary=True)

# ── 1. Set is_tax_inclusive = 1 for all products & set default ──
print("Setting is_tax_inclusive = 1 for all products...")
cursor.execute("ALTER TABLE products MODIFY COLUMN is_tax_inclusive TINYINT(1) DEFAULT 1")
cursor.execute("UPDATE products SET is_tax_inclusive = 1")
db.commit()

cursor.execute("SELECT COUNT(*) as cnt FROM products WHERE is_tax_inclusive = 1")
cnt = cursor.fetchone()["cnt"]
print(f"✅ All {cnt} products are now marked is_tax_inclusive = 1.")

# ── 2. Add Nerolac Machine Colorants ──
BRAND_ID = 1          # Nerolac
CATEGORY_ID = 3       # Stainers
SUBCATEGORY_ID = 8    # Machine Colorant
UNIT_LITRE = 1        # Litre (L)
TAX_18 = 3            # GST 18%

colorants = [
    {
        "name": "Nerolac Machine Colorant White (TI)",
        "sku": "NER-MC-TI",
        "var_sku": "NER-MC-TI-1L",
        "desc": "Nerolac Color Scapes concentrated titanium dioxide white machine colorant for computerized paint dispensing canisters.",
        "buy": 680.0, "sell": 850.0, "mrp": 950.0
    },
    {
        "name": "Nerolac Machine Colorant Yellow Oxide (YO)",
        "sku": "NER-MC-YO",
        "var_sku": "NER-MC-YO-1L",
        "desc": "Nerolac Color Scapes concentrated yellow oxide (ochre) machine colorant for computerized paint dispensing canisters.",
        "buy": 480.0, "sell": 600.0, "mrp": 680.0
    },
    {
        "name": "Nerolac Machine Colorant Red Oxide (RO)",
        "sku": "NER-MC-RO",
        "var_sku": "NER-MC-RO-1L",
        "desc": "Nerolac Color Scapes concentrated red iron oxide machine colorant for computerized paint dispensing canisters.",
        "buy": 480.0, "sell": 600.0, "mrp": 680.0
    },
    {
        "name": "Nerolac Machine Colorant Carbon Black (BL)",
        "sku": "NER-MC-BL",
        "var_sku": "NER-MC-BL-1L",
        "desc": "Nerolac Color Scapes concentrated carbon black machine colorant for computerized paint dispensing canisters.",
        "buy": 450.0, "sell": 550.0, "mrp": 620.0
    },
    {
        "name": "Nerolac Machine Colorant Phthalo Blue (PB)",
        "sku": "NER-MC-PB",
        "var_sku": "NER-MC-PB-1L",
        "desc": "Nerolac Color Scapes concentrated phthalocyanine blue machine colorant for computerized paint dispensing canisters.",
        "buy": 850.0, "sell": 1050.0, "mrp": 1180.0
    },
    {
        "name": "Nerolac Machine Colorant Phthalo Green (PG)",
        "sku": "NER-MC-PG",
        "var_sku": "NER-MC-PG-1L",
        "desc": "Nerolac Color Scapes concentrated phthalocyanine green machine colorant for computerized paint dispensing canisters.",
        "buy": 980.0, "sell": 1200.0, "mrp": 1350.0
    },
    {
        "name": "Nerolac Machine Colorant Fast Yellow (FY)",
        "sku": "NER-MC-FY",
        "var_sku": "NER-MC-FY-1L",
        "desc": "Nerolac Color Scapes concentrated high-strength organic fast yellow machine colorant for computerized paint dispensing canisters.",
        "buy": 1250.0, "sell": 1550.0, "mrp": 1750.0
    },
    {
        "name": "Nerolac Machine Colorant Medium Yellow (MY)",
        "sku": "NER-MC-MY",
        "var_sku": "NER-MC-MY-1L",
        "desc": "Nerolac Color Scapes concentrated medium warm yellow machine colorant for computerized paint dispensing canisters.",
        "buy": 1200.0, "sell": 1500.0, "mrp": 1700.0
    },
    {
        "name": "Nerolac Machine Colorant Fast Red (FR)",
        "sku": "NER-MC-FR",
        "var_sku": "NER-MC-FR-1L",
        "desc": "Nerolac Color Scapes concentrated high-strength organic fast red machine colorant for computerized paint dispensing canisters.",
        "buy": 1450.0, "sell": 1800.0, "mrp": 2050.0
    },
    {
        "name": "Nerolac Machine Colorant Magenta (MG)",
        "sku": "NER-MC-MG",
        "var_sku": "NER-MC-MG-1L",
        "desc": "Nerolac Color Scapes concentrated quinacridone magenta/violet machine colorant for computerized paint dispensing canisters.",
        "buy": 1650.0, "sell": 2050.0, "mrp": 2300.0
    },
    {
        "name": "Nerolac Machine Colorant Raw Umber (RU)",
        "sku": "NER-MC-RU",
        "var_sku": "NER-MC-RU-1L",
        "desc": "Nerolac Color Scapes concentrated raw umber dark brown machine colorant for computerized paint dispensing canisters.",
        "buy": 520.0, "sell": 650.0, "mrp": 750.0
    },
    {
        "name": "Nerolac Machine Colorant Exterior Orange (EO)",
        "sku": "NER-MC-EO",
        "var_sku": "NER-MC-EO-1L",
        "desc": "Nerolac Color Scapes concentrated weather-fast exterior orange machine colorant for computerized paint dispensing canisters.",
        "buy": 1350.0, "sell": 1680.0, "mrp": 1900.0
    },
    {
        "name": "Nerolac Machine Colorant Exterior Red (ER)",
        "sku": "NER-MC-ER",
        "var_sku": "NER-MC-ER-1L",
        "desc": "Nerolac Color Scapes concentrated weather-fast exterior red machine colorant for computerized paint dispensing canisters.",
        "buy": 1550.0, "sell": 1900.0, "mrp": 2150.0
    },
    {
        "name": "Nerolac Machine Colorant Transparent Yellow (TY)",
        "sku": "NER-MC-TY",
        "var_sku": "NER-MC-TY-1L",
        "desc": "Nerolac Color Scapes concentrated transparent oxide gold/yellow machine colorant for computerized paint dispensing canisters.",
        "buy": 1300.0, "sell": 1600.0, "mrp": 1800.0
    }
]

print("\nAdding Nerolac Machine Colorants...")
added_count = 0
for c in colorants:
    # 1. Product
    cursor.execute("SELECT id FROM products WHERE sku = %s", (c["sku"],))
    row = cursor.fetchone()
    if row:
        product_id = row["id"]
        # Ensure is_tax_inclusive is 1
        cursor.execute("UPDATE products SET is_tax_inclusive = 1 WHERE id = %s", (product_id,))
        db.commit()
    else:
        cursor.execute("""
            INSERT INTO products 
                (name, sku, description, brand_id, category_id, subcategory_id, hsn_code, is_tintable, is_tax_inclusive, is_active, created_at, updated_at)
            VALUES 
                (%s, %s, %s, %s, %s, %s, '3204', 0, 1, 1, NOW(), NOW())
        """, (c["name"], c["sku"], c["desc"], BRAND_ID, CATEGORY_ID, SUBCATEGORY_ID))
        db.commit()
        product_id = cursor.lastrowid
        added_count += 1
        print(f"✅ Product: {c['name']} (id={product_id})")

    # 2. Variant (1 Litre)
    cursor.execute("SELECT id FROM product_variants WHERE sku = %s", (c["var_sku"],))
    vrow = cursor.fetchone()
    if not vrow:
        cursor.execute("""
            INSERT INTO product_variants
                (product_id, sku, variant_name, pack_size, unit_id, purchase_price, selling_price, mrp, tax_rate_id, is_active, created_at, updated_at)
            VALUES 
                (%s, %s, '1 Litre Canister', 1.0, %s, %s, %s, %s, %s, 1, NOW(), NOW())
        """, (product_id, c["var_sku"], UNIT_LITRE, c["buy"], c["sell"], c["mrp"], TAX_18))
        db.commit()
        variant_id = cursor.lastrowid
        print(f"   ↳ Variant: {c['var_sku']} | Buy=₹{c['buy']} Sell=₹{c['sell']} MRP=₹{c['mrp']}")

        # 3. Inventory (2 Litres default stock)
        cursor.execute("""
            INSERT INTO inventory (product_variant_id, quantity, minimum_stock, maximum_stock)
            VALUES (%s, 2.0, 1.0, 10.0)
        """, (variant_id,))
        db.commit()

cursor.close()
db.close()
print(f"\n🎉 Added {added_count} Nerolac Machine Colorants successfully!")
