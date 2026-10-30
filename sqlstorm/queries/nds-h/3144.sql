
WITH supplier_summary AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
customer_ranked AS (
    SELECT c.c_custkey,
           c.c_name,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS balance_rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
order_summary AS (
    SELECT o.o_orderkey,
           o.o_totalprice,
           l.l_quantity,
           l.l_discount,
           l.l_tax,
           COALESCE(l.l_returnflag, 'N') AS return_flag,
           SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY o.o_orderkey) AS net_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
),
nation_performance AS (
    SELECT n.n_nationkey,
           n.n_name,
           SUM(o.o_totalprice) AS total_orders
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT r.r_name,
       COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
       COALESCE(SUM(ss.total_cost), 0) AS overall_cost,
       COALESCE(SUM(np.total_orders), 0) AS total_orders_by_nation,
       COUNT(DISTINCT cr.c_custkey) AS elite_customers
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps)
LEFT JOIN supplier_summary ss ON ss.s_suppkey = s.s_suppkey
LEFT JOIN nation_performance np ON np.n_nationkey = n.n_nationkey
LEFT JOIN customer_ranked cr ON cr.balance_rank <= 10
GROUP BY r.r_name
ORDER BY overall_cost DESC, total_orders_by_nation DESC;
