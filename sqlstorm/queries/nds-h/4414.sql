
WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey,
           r.r_name AS region_name, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
), HighValueSuppliers AS (
    SELECT s.s_suppkey AS suppkey, s.s_name AS name, s.s_acctbal AS acctbal, s.region_name
    FROM SupplierDetails s
    WHERE s.rn <= 3
), OrderSummary AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(o.o_orderkey) AS order_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
    COALESCE(SUM(l.l_extendedprice), 0) AS total_revenue,
    hs.region_name,
    o.order_count
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN HighValueSuppliers hs ON s.s_suppkey = hs.suppkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN OrderSummary o ON l.l_orderkey = o.o_orderkey
WHERE p.p_size > 10 AND (hs.region_name IS NOT NULL OR o.order_count > 0)
GROUP BY p.p_partkey, p.p_name, hs.region_name, o.order_count
ORDER BY total_revenue DESC, total_quantity ASC;
