WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS unique_parts_supply
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
CustomerOrderSummary AS (
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
    s.s_name AS supplier_name,
    s.nation AS supplier_nation,
    s.total_avail_qty AS total_available_quantity,
    s.total_supply_cost AS total_supply_cost,
    s.unique_parts_supply AS unique_parts,
    c.c_name AS customer_name,
    c.total_orders AS customer_total_orders,
    c.total_spent AS customer_total_spent,
    c.avg_order_value AS customer_average_order_value
FROM SupplierSummary s
JOIN CustomerOrderSummary c ON s.unique_parts_supply > 5 AND c.total_orders > 3
ORDER BY s.total_supply_cost DESC, c.total_spent DESC
LIMIT 10;
