WITH customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
high_value_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.total_spent,
        co.order_count
    FROM 
        customer_orders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    WHERE 
        co.total_spent > (SELECT AVG(total_spent) FROM customer_orders)
),
supplier_parts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
top_suppliers AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.total_supply_value
    FROM 
        supplier_parts sp
    WHERE 
        sp.total_supply_value > (SELECT AVG(total_supply_value) FROM supplier_parts)
)
SELECT 
    hvc.c_name AS high_value_customer,
    hvc.total_spent AS spent_amount,
    hvc.order_count AS total_orders,
    ts.s_name AS top_supplier,
    ts.total_supply_value AS supplier_value
FROM 
    high_value_customers hvc
CROSS JOIN 
    top_suppliers ts
ORDER BY 
    hvc.total_spent DESC, ts.total_supply_value DESC
LIMIT 10;