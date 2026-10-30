WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS unique_parts_count
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    ss.s_name,
    ss.nation_name,
    ss.total_avail_qty,
    ss.total_supply_cost,
    ss.unique_parts_count,
    cos.c_name AS customer_name,
    cos.total_orders,
    cos.total_spent,
    cos.avg_order_value
FROM SupplierStats ss
JOIN CustomerOrderStats cos ON ss.total_supply_cost > cos.total_spent
ORDER BY ss.total_supply_cost DESC, cos.avg_order_value DESC
LIMIT 10;
