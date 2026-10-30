WITH SupplierStats AS (
    SELECT s.s_nationkey, COUNT(DISTINCT ps.ps_partkey) AS supplier_part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
),
NationStats AS (
    SELECT n.n_nationkey, n.n_name, SUM(ss.supplier_part_count) AS total_parts_supplied
    FROM nation n
    LEFT JOIN SupplierStats ss ON n.n_nationkey = ss.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_orderdate
),
FinalReport AS (
    SELECT ns.n_name, ns.total_parts_supplied, COUNT(os.o_orderkey) AS total_orders, SUM(os.total_revenue) AS revenue
    FROM NationStats ns
    LEFT JOIN OrderStats os ON ns.n_nationkey = os.o_orderkey
    GROUP BY ns.n_name, ns.total_parts_supplied
)
SELECT n_name, total_parts_supplied, total_orders, revenue
FROM FinalReport
WHERE total_orders > 10 AND revenue > 10000
ORDER BY revenue DESC, total_orders DESC;
