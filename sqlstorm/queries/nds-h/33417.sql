WITH  SupplyChain AS (
    SELECT s_suppkey, s_name, s_acctbal, s_comment, 
           ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rn
    FROM supplier
    WHERE s_acctbal > 1000
), OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_orderkey) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice
), SupplierStats AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT p.p_partkey, p.p_name, p.p_retailprice, 
       COALESCE(SC.rn, 0) AS supplier_rank,
       OD.total_revenue, SS.total_avail_qty, SS.avg_supply_cost
FROM part p
LEFT JOIN SupplyChain SC ON p.p_partkey = SC.s_suppkey
FULL OUTER JOIN OrderDetails OD ON p.p_partkey = OD.o_orderkey
JOIN SupplierStats SS ON p.p_partkey = SS.ps_partkey
WHERE (p.p_size > 10 OR p.p_container = 'MED BOX')
  AND (OD.total_revenue IS NOT NULL OR SS.total_avail_qty > 0)
  AND (SC.s_acctbal IS NULL OR SC.s_acctbal < 5000)
ORDER BY p.p_retailprice DESC, OD.total_revenue DESC
LIMIT 100;
