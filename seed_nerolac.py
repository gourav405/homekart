import mysql.connector
import random

db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Thinksys@123",
    database="homekart"
)
cursor = db.cursor()

# Wipe everything cleanly
cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
tables_to_truncate = [
    "sale_returns_log", "sale_items", "sales",
    "purchase_items", "purchases", "stock_movements",
    "inventory", "product_variants", "products", "brands", "categories",
    "audit_log", "refunds", "customer_payments", "supplier_payments"
]
for table in tables_to_truncate:
    cursor.execute(f"TRUNCATE TABLE {table}")
cursor.execute("SET FOREIGN_KEY_CHECKS = 1")

# Get Litre unit ID
cursor.execute("SELECT id FROM units WHERE symbol='L'")
res = cursor.fetchone()
if res:
    unit_l = res[0]
else:
    cursor.execute("INSERT INTO units (name, symbol) VALUES ('Litre', 'L')")
    unit_l = cursor.lastrowid

shades = ["White", "Base 1", "Base 2", "Base 3", "Base 4", "Base 5", "Base 6", "Base 7", "Base 8", "Base 9"]
colors = {}

for shade in shades:
    code = shade[:3].upper() + (shade[-1] if "Base" in shade else "")
    try:
        cursor.execute("INSERT INTO colors (name, code, is_active) VALUES (%s, %s, 1)", (shade, code))
        colors[shade] = cursor.lastrowid
    except mysql.connector.errors.IntegrityError:
        cursor.execute("SELECT id FROM colors WHERE name=%s", (shade,))
        colors[shade] = cursor.fetchone()[0]

# Insert Brand
cursor.execute("INSERT INTO brands (name) VALUES ('Nerolac')")
brand_id = cursor.lastrowid

# Insert Categories
cursor.execute("INSERT INTO categories (name) VALUES ('Interior Emulsion')")
cat_int = cursor.lastrowid
cursor.execute("INSERT INTO categories (name) VALUES ('Exterior Emulsion')")
cat_ext = cursor.lastrowid

products = [
    ("Beauty Little Master", cat_int),
    ("Suraksha", cat_ext),
    ("Suraksha Plus", cat_ext),
    ("Suraksha Sheen", cat_ext),
    ("Excel", cat_ext),
    ("Excel No Dust", cat_ext),
    ("Excel Mica Marble Stretch and Sheen", cat_ext),
    ("Beauty Gold", cat_int),
    ("Beauty Gold Washable", cat_int),
    ("Excel Sheen", cat_ext),
    ("Impression HD", cat_int),
    ("Impression Kashmir", cat_int),
    ("Perma", cat_ext)
]

sizes = [1.0, 4.0, 10.0, 20.0]

for p_name, cat in products:
    p_sku = f"NER-{p_name[:4].upper()}-{random.randint(100,999)}".replace(" ", "")
    cursor.execute("INSERT INTO products (name, sku, brand_id, category_id, is_tintable, is_active) VALUES (%s, %s, %s, %s, 1, 1)", (p_name, p_sku, brand_id, cat))
    product_id = cursor.lastrowid
    
    for shade in shades:
        for size in sizes:
            v_sku = f"NER-{p_name[:3].upper()}-{shade[:3].upper()}-{int(size)}L-{random.randint(1000,9999)}".replace(" ", "")
            color_id = colors[shade]
            cursor.execute("""
                INSERT INTO product_variants 
                (product_id, sku, unit_id, pack_size, color_id, purchase_price, selling_price, mrp) 
                VALUES (%s, %s, %s, %s, %s, 0, 0, 0)
            """, (product_id, v_sku, unit_l, size, color_id))
            
            variant_id = cursor.lastrowid
            cursor.execute("INSERT INTO inventory (product_variant_id, quantity) VALUES (%s, 0)", (variant_id,))

db.commit()
cursor.close()
db.close()
print("Success")
