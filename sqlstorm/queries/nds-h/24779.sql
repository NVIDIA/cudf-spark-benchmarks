
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01' 
      AND o.o_orderdate < DATE '1997-12-31'
), SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_availability,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
), MonthlySales AS (
    SELECT 
        DATE_TRUNC('month', l.l_shipdate) AS month,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    WHERE l.l_shipdate IS NOT NULL
    GROUP BY DATE_TRUNC('month', l.l_shipdate)
)
SELECT 
    r.r_name,
    COALESCE(SUM(sa.total_availability), 0) AS total_availability,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(o.o_totalprice) AS avg_order_value,
    SUM(m.total_sales) AS total_monthly_sales,
    CASE 
        WHEN SUM(m.total_sales) > 100000 THEN 'High Performer'
        ELSE 'Needs Improvement'
    END AS performance_category
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN SupplierAvailability sa ON sa.ps_suppkey = s.s_suppkey
LEFT JOIN RankedOrders o ON o.o_orderkey IN (
    SELECT o1.o_orderkey 
    FROM orders o1 
    WHERE o1.o_orderstatus = 'F' 
      AND o1.o_orderkey > 1000
) 
LEFT JOIN MonthlySales m ON m.month = DATE_TRUNC('month', o.o_orderdate)
WHERE r.r_name IS NOT NULL 
      AND (s.s_acctbal IS NULL OR s.s_acctbal > 0)
GROUP BY r.r_name
HAVING SUM(COALESCE(m.total_sales, 0)) > 50000
ORDER BY total_orders DESC, avg_order_value ASC
LIMIT 10;
