
WITH  SupplierRegion AS (
    SELECT s.s_suppkey, s.s_name, r.r_name, s.s_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE r.r_name = 'ASIA'
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, r.r_name, s.s_acctbal
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE r.r_name <> 'ASIA' AND ps.ps_availqty > 100
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_linenumber) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
),
HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(o.total_revenue) AS total_revenue
    FROM SupplierRegion s
    JOIN OrderStats o ON s.s_suppkey = o.o_orderkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(o.total_revenue) > 10000
)
SELECT sr.r_name, COUNT(DISTINCT h.s_suppkey) AS supplier_count, 
       AVG(h.total_revenue) AS avg_revenue
FROM SupplierRegion sr
LEFT JOIN HighValueSuppliers h ON sr.s_suppkey = h.s_suppkey
GROUP BY sr.r_name
HAVING AVG(h.total_revenue) IS NOT NULL
ORDER BY avg_revenue DESC;
