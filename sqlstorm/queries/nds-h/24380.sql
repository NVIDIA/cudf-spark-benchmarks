WITH  SupplierProfit AS (
    SELECT s_suppkey, 
           (SUM(ps_supplycost * ps_availqty) - SUM(CASE WHEN l_discount > 0.1 THEN l_extendedprice ELSE 0 END)) AS total_profit
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey AND l.l_returnflag = 'N'
    GROUP BY s_suppkey
),
RegionNation AS (
    SELECT r.r_regionkey, 
           r.r_name, 
           n.n_name, 
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name, n.n_name
),
HighValueOrders AS (
    SELECT o_orderkey,
           o_custkey,
           SUM(l_extendedprice * (1 - l_discount)) AS high_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o_orderkey, o_custkey
    HAVING SUM(l_extendedprice * (1 - l_discount)) > 10000
),
QuarterlyRevenue AS (
    SELECT EXTRACT(YEAR FROM o_orderdate) AS order_year,
           EXTRACT(QUARTER FROM o_orderdate) AS order_quarter,
           SUM(o_totalprice) AS total_revenue
    FROM orders o
    WHERE o_orderstatus IN ('O', 'F')
    GROUP BY order_year, order_quarter
)
SELECT rn.r_name, 
       rn.n_name, 
       SUM(sp.total_profit) AS total_supplier_profit,
       SUM(qr.total_revenue) AS region_revenue,
       CASE
           WHEN SUM(qr.total_revenue) IS NULL THEN 'No Revenue'
           WHEN SUM(sp.total_profit) IS NULL THEN 'No Profit'
           ELSE 'Metrics Calculated'
       END AS calculation_status
FROM RegionNation rn
LEFT JOIN SupplierProfit sp ON rn.supplier_count > 0
LEFT JOIN QuarterlyRevenue qr ON rn.r_regionkey = qr.order_year % 5
WHERE rn.supplier_count > 10
GROUP BY rn.r_name, rn.n_name
HAVING SUM(sp.total_profit) IS NOT NULL OR SUM(qr.total_revenue) IS NOT NULL
ORDER BY total_supplier_profit DESC, region_revenue ASC
LIMIT 10;
