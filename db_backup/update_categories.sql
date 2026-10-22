SET FOREIGN_KEY_CHECKS = 0;

-- 1. Re-populate Categories
TRUNCATE TABLE categories;
INSERT INTO categories (id, name, is_active) VALUES
(1, 'Interior Emulsion', 1),
(2, 'Exterior Emulsion', 1),
(3, 'Stainers', 1),
(4, 'Enamel', 1),
(5, 'Distemper', 1),
(6, 'Primers', 1),
(7, 'Putty & Patti', 1),
(8, 'Waterproofing', 1),
(9, 'Brushes', 1),
(10, 'Rollers', 1),
(11, 'Sandpaper & Abrasives', 1),
(12, 'Thinners & Solvents', 1),
(13, 'Adhesives', 1),
(14, 'Tools', 1),
(15, 'Hardware & Fasteners', 1),
(16, 'Plumbing', 1),
(17, 'Electrical', 1);

-- 2. Re-populate Subcategories
TRUNCATE TABLE subcategories;
INSERT INTO subcategories (id, name, category_id, is_active) VALUES
-- Interior Emulsion (1)
(1, 'Standard Interior Emulsion', 1, 1),
(2, 'Premium Interior Emulsion', 1, 1),
(3, 'Luxury / Washable Emulsion', 1, 1),

-- Exterior Emulsion (2)
(4, 'Standard Exterior Paint', 2, 1),
(5, 'Weatherproof Exterior Emulsion', 2, 1),
(6, 'High Sheen & Dirtproof Emulsion', 2, 1),

-- Stainers (3)
(7, 'Universal Stainer', 3, 1),
(8, 'Machine Colorant', 3, 1),

-- Enamel (4)
(9, 'Synthetic Enamel', 4, 1),
(10, 'PU Enamel', 4, 1),
(11, 'Satin / Gloss Enamel', 4, 1),

-- Distemper (5)
(12, 'Acrylic Distemper', 5, 1),
(13, 'Synthetic Distemper', 5, 1),

-- Primers (6)
(14, 'Interior Wall Primer', 6, 1),
(15, 'Exterior Wall Primer', 6, 1),
(16, 'Metal Primer (Red Oxide)', 6, 1),
(17, 'Wood Primer', 6, 1),
(18, 'Cement Primer', 6, 1),

-- Putty & Patti (7)
(19, 'Acrylic Wall Putty', 7, 1),
(20, 'White Cement Putty', 7, 1),
(21, 'Waterproof Putty', 7, 1),
(22, 'Putty Paati / Blade', 7, 1),

-- Waterproofing (8)
(23, 'Roof Waterproofing', 8, 1),
(24, 'Wall Waterproofing / Damp Proof', 8, 1),
(25, 'Bathroom Waterproofing', 8, 1),

-- Brushes (9)
(26, 'Paint Brush', 9, 1),
(27, 'Bristle Brush', 9, 1),
(28, 'Synthetic Brush', 9, 1),
(29, 'Wire Brush', 9, 1),
(30, 'Cleaning Brush', 9, 1),

-- Rollers (10)
(31, 'Paint Roller', 10, 1),
(32, 'Texture Roller', 10, 1),
(33, 'Roller Sleeve / Refill', 10, 1),

-- Sandpaper & Abrasives (11)
(34, 'Waterproof Sheet Sandpaper', 11, 1),
(35, 'Disc Sandpaper / Sanding Disc', 11, 1),
(36, 'Emery Cloth Roll', 11, 1),

-- Thinners & Solvents (12)
(37, 'General Purpose Thinner', 12, 1),
(38, 'PU Thinner', 12, 1),
(39, 'Mineral Turpentine', 12, 1),

-- Adhesives (13)
(40, 'Wood Adhesive (Fevicol/Bond)', 13, 1),
(41, 'Tile Adhesive', 13, 1),

-- Tools (14)
(42, 'Screwdrivers', 14, 1),
(43, 'Hammers', 14, 1),
(44, 'Drill Bits', 14, 1),
(45, 'Scrapers & Blades', 14, 1),

-- Hardware & Fasteners (15)
(46, 'Nuts & Bolts', 15, 1),
(47, 'Hinges', 15, 1),
(48, 'Locks', 15, 1),
(49, 'Masking & Packing Tapes', 15, 1),

-- Plumbing (16)
(50, 'Pipes & Fittings', 16, 1),
(51, 'Taps & Valves', 16, 1),

-- Electrical (17)
(52, 'Switches & Sockets', 17, 1),
(53, 'Wires & Cables', 17, 1);

-- 3. Set universal availability for product_types
UPDATE product_types SET subcategory_id = NULL;

-- 4. Re-map Existing Products
-- Interior Emulsions
UPDATE products SET category_id = 1, subcategory_id = 1 WHERE id IN (1); -- Beauty Little Master
UPDATE products SET category_id = 1, subcategory_id = 2 WHERE id IN (8); -- Beauty Gold
UPDATE products SET category_id = 1, subcategory_id = 3 WHERE id IN (9, 11, 12); -- Beauty Gold Washable, Impression HD, Kashmir

-- Exterior Emulsions
UPDATE products SET category_id = 2, subcategory_id = 4 WHERE id IN (2, 3); -- Suraksha, Suraksha Plus
UPDATE products SET category_id = 2, subcategory_id = 5 WHERE id IN (5, 13); -- Excel, Perma
UPDATE products SET category_id = 2, subcategory_id = 6 WHERE id IN (4, 6, 7, 10); -- Suraksha Sheen, Excel No Dust, Mica Marble, Excel Sheen

-- Stainers
UPDATE products SET category_id = 3, subcategory_id = 7 WHERE id BETWEEN 14 AND 24;

-- Putty & Patti
UPDATE products SET category_id = 7, subcategory_id = 19 WHERE id IN (25, 29); -- Acrylic Putty
UPDATE products SET category_id = 7, subcategory_id = 21 WHERE id IN (28, 30); -- Waterproof Putty

-- Brushes
UPDATE products SET category_id = 9, subcategory_id = 26 WHERE id IN (31, 32, 33);

SET FOREIGN_KEY_CHECKS = 1;
