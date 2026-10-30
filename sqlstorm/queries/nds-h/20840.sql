WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
), SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           SUM(ps.ps_availqty) AS total_availability, 
           AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY ps.ps_partkey, ps.ps_suppkey
), LineItemAnalysis AS (
    SELECT l.l_orderkey, 
           COUNT(l.l_linenumber) AS line_count,
           SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM lineitem l
    GROUP BY l.l_orderkey
), RegionSupplier AS (
    SELECT r.r_regionkey, r.r_name, 
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT ro.o_orderkey, ro.o_orderstatus, ro.o_totalprice, ro.o_orderdate,
       COALESCE(lp.line_count, 0) AS line_count,
       COALESCE(sp.total_availability, 0) AS total_availability,
       CASE 
           WHEN sp.avg_supplycost IS NOT NULL THEN ROUND(sp.avg_supplycost, 2)
           ELSE NULL 
       END AS avg_supplycost,
       rs.supplier_count
FROM RankedOrders ro
LEFT JOIN LineItemAnalysis lp ON ro.o_orderkey = lp.l_orderkey
LEFT JOIN SupplierParts sp ON ro.o_orderkey = sp.ps_partkey
LEFT JOIN RegionSupplier rs ON rs.supplier_count > 2
WHERE ro.order_rank <= 5 
  AND (ro.o_totalprice >= 100 OR ro.o_orderdate < cast('1998-10-01' as date) - INTERVAL '30 days')
ORDER BY ro.o_totalprice DESC, rs.r_regionkey ASC
LIMIT 100;