
WITH supplier_part_costs AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
top_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        spc.total_supply_cost
    FROM 
        supplier s
    JOIN 
        supplier_part_costs spc ON s.s_suppkey = spc.s_suppkey
    WHERE 
        spc.total_supply_cost > (SELECT AVG(total_supply_cost) FROM supplier_part_costs)
    ORDER BY 
        spc.total_supply_cost DESC
    LIMIT 5
)

SELECT 
    co.c_custkey,
    co.order_count,
    co.total_spent,
    ts.s_name AS top_supplier_name,
    ts.total_supply_cost AS supplier_cost
FROM 
    customer_orders co
LEFT JOIN 
    top_suppliers ts ON co.order_count > (SELECT AVG(order_count) FROM customer_orders)
WHERE 
    co.total_spent IS NOT NULL 
    AND co.order_count > 0
ORDER BY 
    co.total_spent DESC, ts.total_supply_cost ASC;
