
WITH ranked_suppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
high_value_suppliers AS (
    SELECT 
        supp.s_suppkey, 
        supp.s_name
    FROM 
        ranked_suppliers supp
    WHERE 
        supp.rank <= 10
),
customer_orders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    hs.s_name AS supplier_name,
    co.c_name AS customer_name,
    co.order_count,
    r.part_count,
    r.total_available_quantity,
    r.total_supply_cost
FROM 
    high_value_suppliers hs
JOIN 
    ranked_suppliers r ON hs.s_suppkey = r.s_suppkey
CROSS JOIN 
    customer_orders co
WHERE 
    co.order_count > 5
ORDER BY 
    r.total_supply_cost DESC, co.order_count DESC;
