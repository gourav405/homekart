import sys
sql = "SET FOREIGN_KEY_CHECKS = 0;\n"
sql += "INSERT INTO brands (name) VALUES ('Nerolac');\n"
sql += "SET @brand_id = LAST_INSERT_ID();\n"
sql += "INSERT INTO categories (name) VALUES ('Interior Emulsion');\n"
sql += "SET @cat_int = LAST_INSERT_ID();\n"
sql += "INSERT INTO categories (name) VALUES ('Exterior Emulsion');\n"
sql += "SET @cat_ext = LAST_INSERT_ID();\n"

products = [
    ("Beauty Little Master", "@cat_int"),
    ("Suraksha", "@cat_ext"),
    ("Suraksha Plus", "@cat_ext"),
    ("Suraksha Sheen", "@cat_ext"),
    ("Excel", "@cat_ext"),
    ("Excel No Dust", "@cat_ext"),
    ("Excel Mica Marble Stretch and Sheen", "@cat_ext"),
    ("Beauty Gold", "@cat_int"),
    ("Beauty Gold Washable", "@cat_int"),
    ("Excel Sheen", "@cat_ext"),
    ("Impression HD", "@cat_int"),
    ("Impression Kashmir", "@cat_int"),
    ("Perma", "@cat_ext")
]

shades = ["White", "Base 1", "Base 2", "Base 3", "Base 4", "Base 5", "Base 6", "Base 7", "Base 8", "Base 9"]
sizes = [
    ("1", "Liters"),
    ("4", "Liters"),
    ("10", "Liters"),
    ("20", "Liters")
]

import random
for p_name, cat in products:
    p_sku = f"NER-{p_name[:4].upper()}-{random.randint(100,999)}".replace(" ", "")
    sql += f"INSERT INTO products (name, sku, brand_id, category_id, is_tintable, is_active) VALUES ('{p_name}', '{p_sku}', @brand_id, {cat}, 1, 1);\n"
    sql += "SET @product_id = LAST_INSERT_ID();\n"
    for shade in shades:
        for size_val, size_unit in sizes:
            v_sku = f"NER-{p_name[:3].upper()}-{shade[:3].upper()}-{size_val}L-{random.randint(1000,9999)}".replace(" ", "")
            sql += f"INSERT INTO product_variants (product_id, sku, size_value, size_unit, color_name, purchase_price, selling_price, mrp, stock_quantity, reorder_level) VALUES (@product_id, '{v_sku}', '{size_val}', '{size_unit}', '{shade}', 0, 0, 0, 0, 0);\n"
sql += "SET FOREIGN_KEY_CHECKS = 1;\n"

with open("seed.sql", "w") as f:
    f.write(sql)
print("SQL generated")
