WITH FilteredParts AS (
    SELECT p_partkey, p_name, p_mfgr, p_brand,
           CASE 
               WHEN LENGTH(p_comment) > 20 THEN SUBSTRING(p_comment, 1, 20) || '...' 
               ELSE p_comment 
           END AS short_comment
    FROM part
    WHERE p_retailprice > 50.00
), SupplierStats AS (
    SELECT s_nationkey, AVG(s_acctbal) AS avg_acctbal, COUNT(*) AS supplier_count
    FROM supplier
    GROUP BY s_nationkey
), CustomerOrders AS (
    SELECT c.c_custkey, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT r.r_name, 
       COUNT(DISTINCT f.p_partkey) AS part_count, 
       s.avg_acctbal, 
       c.order_count
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierStats s ON n.n_nationkey = s.s_nationkey
LEFT JOIN FilteredParts f ON f.p_brand LIKE 'Brand%'
LEFT JOIN CustomerOrders c ON n.n_nationkey = c.c_custkey
GROUP BY r.r_name, s.avg_acctbal, c.order_count
ORDER BY r.r_name;
