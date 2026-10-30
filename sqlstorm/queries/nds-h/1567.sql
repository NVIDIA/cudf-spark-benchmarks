
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
    HAVING SUM(o.o_totalprice) > 10000
)
SELECT 
    r.r_name AS region_name, 
    n.n_name AS nation_name, 
    s.s_name AS supplier_name, 
    hvc.c_name AS customer_name, 
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) IS NULL THEN 'No Sales'
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000 THEN 'High Value Sale'
        ELSE 'Regular Sale'
    END AS sale_category,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey AND rs.rn = 1
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN HighValueCustomers hvc ON o.o_custkey = hvc.c_custkey
GROUP BY r.r_name, n.n_name, s.s_name, hvc.c_name
ORDER BY total_sales DESC
LIMIT 10;
