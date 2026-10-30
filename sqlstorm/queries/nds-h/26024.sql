WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           (CASE 
                WHEN LENGTH(s.s_name) < 10 THEN 'Short'
                WHEN LENGTH(s.s_name) BETWEEN 10 AND 20 THEN 'Medium'
                ELSE 'Long'
            END) AS name_length_category,
           s.s_comment
    FROM supplier s
),
PartInfo AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type,
           (CASE
                WHEN p.p_size BETWEEN 1 AND 10 THEN 'Small'
                WHEN p.p_size BETWEEN 11 AND 20 THEN 'Medium'
                ELSE 'Large'
            END) AS size_category,
           p.p_comment
    FROM part p
),
LineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, 
           SUM(l.l_quantity) AS total_quantity,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           COUNT(DISTINCT l.l_linenumber) AS num_line_items
    FROM lineitem l
    GROUP BY l.l_orderkey, l.l_partkey, l.l_suppkey
)
SELECT si.s_name, si.name_length_category, pi.p_brand, pi.size_category,
       li.total_quantity, li.total_price, li.num_line_items
FROM SupplierInfo si
JOIN LineItems li ON si.s_suppkey = li.l_suppkey
JOIN PartInfo pi ON li.l_partkey = pi.p_partkey
WHERE pi.p_type LIKE '%metal%'
AND si.s_comment NOT LIKE '%important%'
ORDER BY total_price DESC, si.s_name ASC
LIMIT 100;
