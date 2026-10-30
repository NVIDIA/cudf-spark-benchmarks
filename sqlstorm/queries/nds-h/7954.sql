WITH SupplierOrderSummary AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE s.s_acctbal > 1000
    GROUP BY s.s_suppkey, s.s_name
),
RegionWiseSummary AS (
    SELECT n.n_regionkey, r.r_name, SUM(sos.total_revenue) AS regional_revenue, 
           SUM(sos.total_orders) AS regional_orders
    FROM SupplierOrderSummary sos
    JOIN supplier s ON sos.s_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_regionkey, r.r_name
)
SELECT rws.r_name, rws.regional_revenue, rws.regional_orders
FROM RegionWiseSummary rws
WHERE rws.regional_revenue > (
    SELECT AVG(regional_revenue) FROM RegionWiseSummary
)
ORDER BY rws.regional_revenue DESC;
