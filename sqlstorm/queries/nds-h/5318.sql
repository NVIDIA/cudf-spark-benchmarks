WITH supplier_part AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),

top_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sp.total_supply_cost
    FROM 
        supplier s
    JOIN 
        supplier_part sp ON s.s_suppkey = sp.s_suppkey
    ORDER BY 
        sp.total_supply_cost DESC
    LIMIT 10
),

customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    cu.c_name AS customer_name,
    cu.order_count,
    cu.total_spent,
    ts.s_name AS supplier_name,
    ts.total_supply_cost
FROM 
    customer_orders cu
CROSS JOIN 
    top_suppliers ts
WHERE 
    cu.total_spent > 10000
ORDER BY 
    cu.total_spent DESC, ts.total_supply_cost DESC;
