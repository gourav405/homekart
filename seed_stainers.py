import mysql.connector
import random

db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Thinksys@123",
    database="homekart"
)
cursor = db.cursor()

# Get Brand
cursor.execute("SELECT id FROM brands WHERE name='Nerolac'")
brand_id = cursor.fetchone()[0]

# Category
cursor.execute("INSERT INTO categories (name) VALUES ('Stainers')")
cat_stainer = cursor.lastrowid

# Get Gram unit
cursor.execute("SELECT id FROM units WHERE symbol='G'")
res = cursor.fetchone()
if res:
    unit_g = res[0]
else:
    cursor.execute("INSERT INTO units (name, symbol) VALUES ('Gram', 'G')")
    unit_g = cursor.lastrowid

# Get N/A color
cursor.execute("SELECT id FROM colors WHERE code='NA'")
res = cursor.fetchone()
if res:
    color_na = res[0]
else:
    cursor.execute("INSERT INTO colors (name, code, is_active) VALUES ('N/A', 'NA', 1)")
    color_na = cursor.lastrowid

stainers = [
    "Yellow Oxide", "Fast Yellow", "Fast Yellow Green", "Fast Green",
    "Black", "Magenta", "Fast Blue", "Fast Red", "Orange",
    "Turkey Umber", "Bright Green"
]
sizes = [50.0, 100.0, 200.0]

for s_name in stainers:
    p_name = f"{s_name} Stainer"
    p_sku = f"NER-STN-{s_name[:3].upper()}-{random.randint(100,999)}".replace(" ", "")
    # is_tintable = 0 since these are colorants themselves
    cursor.execute("INSERT INTO products (name, sku, brand_id, category_id, is_tintable, is_active) VALUES (%s, %s, %s, %s, 0, 1)", (p_name, p_sku, brand_id, cat_stainer))
    product_id = cursor.lastrowid
    
    for size in sizes:
        v_sku = f"NER-STN-{s_name[:3].upper()}-{int(size)}G-{random.randint(1000,9999)}".replace(" ", "")
        cursor.execute("""
            INSERT INTO product_variants 
            (product_id, sku, unit_id, pack_size, color_id, purchase_price, selling_price, mrp) 
            VALUES (%s, %s, %s, %s, %s, 0, 0, 0)
        """, (product_id, v_sku, unit_g, size, color_na))
        
        variant_id = cursor.lastrowid
        cursor.execute("INSERT INTO inventory (product_variant_id, quantity) VALUES (%s, 0)", (variant_id,))

db.commit()
cursor.close()
db.close()
print("Stainers seeded successfully!")
