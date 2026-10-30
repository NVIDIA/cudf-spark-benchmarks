WITH supplier_part_stats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(ps.ps_partkey) AS total_parts, 
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
customer_order_stats AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS total_orders, 
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
order_line_stats AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value,
        COUNT(l.l_linenumber) AS total_line_items
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    sp.s_name,
    cs.c_name,
    o.total_line_value,
    o.total_line_items,
    sp.total_parts,
    sp.total_supply_cost,
    cs.total_orders,
    cs.total_spent
FROM supplier_part_stats sp
JOIN order_line_stats o ON sp.s_suppkey = o.o_orderkey 
JOIN customer_order_stats cs ON sp.s_suppkey = cs.c_custkey 
WHERE o.total_line_value > 1000
ORDER BY sp.total_supply_cost DESC, cs.total_spent ASC
LIMIT 100;