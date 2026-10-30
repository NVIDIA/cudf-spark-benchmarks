WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 30000 AND sh.level < 3
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    SUM(COALESCE(ps.ps_availqty, 0)) AS total_available_quantity,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    AVG(o.o_totalprice) AS avg_order_price,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    STRING_AGG(DISTINCT p.p_name, ', ') AS products_list
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
WHERE 
    r.r_name LIKE 'S%' 
    AND (s.s_acctbal IS NOT NULL AND s.s_acctbal >= (SELECT AVG(s_acctbal) FROM supplier))
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    r.r_name, n.n_name
HAVING 
    SUM(ps.ps_availqty) > 10000
    AND COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_available_quantity DESC, avg_order_price ASC
LIMIT 10 OFFSET 0