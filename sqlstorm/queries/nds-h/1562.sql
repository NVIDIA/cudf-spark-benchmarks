WITH SupplierSummary AS (
    SELECT s_nationkey, COUNT(*) AS supplier_count, AVG(s_acctbal) AS avg_acctbal
    FROM supplier
    GROUP BY s_nationkey
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, l.l_quantity, l.l_discount,
           SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY o.o_orderkey) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F' AND l.l_shipdate >= '1997-01-01'
),
NationRegion AS (
    SELECT n.n_name, r.r_name, n.n_nationkey
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT nr.n_name AS nation_name, nr.r_name AS region_name,
       ss.supplier_count, ss.avg_acctbal, 
       COUNT(od.o_orderkey) AS total_orders,
       SUM(od.revenue) AS total_revenue
FROM NationRegion nr
LEFT JOIN SupplierSummary ss ON nr.n_nationkey = ss.s_nationkey
LEFT JOIN OrderDetails od ON nr.n_nationkey = od.o_orderkey
GROUP BY nr.n_name, nr.r_name, ss.supplier_count, ss.avg_acctbal
HAVING COUNT(od.o_orderkey) > 0 AND AVG(ss.avg_acctbal) > 1000
ORDER BY total_revenue DESC NULLS LAST;