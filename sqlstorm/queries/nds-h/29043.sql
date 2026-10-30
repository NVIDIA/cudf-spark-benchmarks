WITH SupplierParts AS (
    SELECT s.s_name AS supplier_name, p.p_name AS part_name, 
           CONCAT(s.s_name, ' supplies ', p.p_name) AS supply_info,
           LENGTH(s.s_comment) AS comment_length, 
           SUBSTRING(s.s_comment, 1, 30) AS short_comment,
           COUNT(ps.ps_availqty) AS available_quantity
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_name, p.p_name, s.s_comment
),
PartDetails AS (
    SELECT p.p_name, p.p_retailprice, 
           CASE 
               WHEN p.p_retailprice < 500 THEN 'Low'
               WHEN p.p_retailprice BETWEEN 500 AND 1000 THEN 'Medium'
               ELSE 'High' 
           END AS price_category
    FROM part p
)
SELECT sp.supplier_name, sp.part_name, 
       pd.p_retailprice, pd.price_category, 
       sp.short_comment, sp.available_quantity
FROM SupplierParts sp
JOIN PartDetails pd ON sp.part_name = pd.p_name
WHERE sp.comment_length > 20
ORDER BY sp.available_quantity DESC, pd.p_retailprice ASC
LIMIT 50;
