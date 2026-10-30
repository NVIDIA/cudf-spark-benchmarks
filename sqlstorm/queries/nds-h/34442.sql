WITH  nation_supplier AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
),
high_value_orders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT c.c_custkey) AS customer_count,
           ROW_NUMBER() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus IN ('F', 'O')
    GROUP BY o.o_orderkey
),
supplier_part AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_name, SUM(ps.ps_supplycost) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey, p.p_name
)
SELECT ns.n_name, COALESCE(hvo.total_revenue, 0) AS max_revenue, 
       COALESCE(sp.total_supply_cost, 0) AS total_supply_cost, 
       sp.supplier_count
FROM nation_supplier ns
LEFT JOIN high_value_orders hvo ON ns.n_nationkey = hvo.o_orderkey
LEFT JOIN supplier_part sp ON ns.s_suppkey = sp.ps_suppkey
WHERE ns.rnk = 1
  AND (hvo.total_revenue > 10000 OR sp.total_supply_cost IS NULL)
ORDER BY ns.n_name, max_revenue DESC;
