WITH supplier_stats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
order_summary AS (
    SELECT 
        o.o_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        SUM(l.l_quantity) AS total_quantity
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_custkey
)
SELECT 
    ss.s_name,
    ss.nation,
    ss.total_cost,
    os.total_orders,
    os.revenue,
    os.total_quantity
FROM supplier_stats ss
LEFT JOIN order_summary os ON ss.s_suppkey = os.o_custkey
WHERE ss.part_count > 10 AND os.total_orders > 5
ORDER BY ss.total_cost DESC, os.revenue DESC
LIMIT 100;
