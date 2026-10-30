WITH NationSupplier AS (
    SELECT n.n_nationkey, n.n_name, s.s_suppkey, s.s_name, s.s_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
), PartsSupplied AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_avail_qty, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
), OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY o.o_orderkey
)
SELECT ns.n_name, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, SUM(ps.total_supply_cost) AS total_cost,
       SUM(od.total_revenue) AS total_revenue
FROM NationSupplier ns
JOIN PartsSupplied ps ON ns.s_suppkey = ps.ps_suppkey
JOIN OrderDetails od ON ps.ps_partkey = od.o_orderkey
WHERE ns.s_acctbal > 1000
GROUP BY ns.n_name
ORDER BY total_revenue DESC, total_cost ASC;