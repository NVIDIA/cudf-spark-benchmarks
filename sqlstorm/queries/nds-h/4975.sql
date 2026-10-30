WITH supplier_stats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
ranked_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_supply_cost,
        ss.part_count,
        RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS cost_rank
    FROM 
        supplier_stats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
),
ranked_customers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_order_value,
        co.total_orders,
        RANK() OVER (ORDER BY co.total_order_value DESC) AS order_rank
    FROM 
        customer_orders co
)
SELECT 
    rs.s_name AS supplier_name,
    rc.c_name AS customer_name,
    rs.total_supply_cost,
    rc.total_order_value,
    CASE 
        WHEN rc.total_order_value IS NULL THEN 'No orders'
        ELSE CONCAT('Orders: ', rc.total_orders)
    END AS order_summary
FROM 
    ranked_suppliers rs 
FULL OUTER JOIN 
    ranked_customers rc ON rs.cost_rank = rc.order_rank
WHERE 
    rs.total_supply_cost > 10000
   OR rc.total_order_value IS NOT NULL
ORDER BY 
    rs.total_supply_cost DESC, rc.total_order_value DESC;
