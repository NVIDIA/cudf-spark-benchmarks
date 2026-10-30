
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_orderstatus,
        COUNT(l.l_orderkey) AS line_count,
        SUM(l.l_extendedprice) AS total_order_value,
        ROW_NUMBER() OVER(PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice) DESC) AS order_ranking
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1995-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_orderstatus
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    SUM(od.total_order_value) AS total_order_value,
    AVG(sd.total_quantity) AS avg_quantity_supplied
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierDetails sd ON s.s_suppkey = sd.s_suppkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN OrderDetails od ON c.c_custkey = od.o_orderkey
WHERE 
    r.r_name IS NOT NULL 
    AND s.s_acctbal < COALESCE((SELECT AVG(s_acctbal) FROM supplier), 0) 
    AND (s.s_name LIKE '%Supplier%' OR s.s_name IS NULL)
GROUP BY r.r_name
HAVING COUNT(DISTINCT od.o_orderkey) > 5
ORDER BY total_order_value DESC;
