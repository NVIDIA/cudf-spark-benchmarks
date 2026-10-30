WITH  customer_order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        SUM(l.l_quantity) AS total_items
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),

supplier_performance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),

top_customers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(co.total_spent) AS total_customer_spent
    FROM 
        customer_order_summary co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    ORDER BY 
        total_customer_spent DESC
    LIMIT 10
)

SELECT 
    tc.c_name AS customer_name,
    tc.total_customer_spent,
    sp.s_name AS supplier_name,
    sp.avg_supply_cost,
    sp.supplied_parts
FROM 
    top_customers tc
CROSS JOIN 
    supplier_performance sp
WHERE 
    tc.total_customer_spent > (SELECT AVG(total_spent) FROM customer_order_summary)
ORDER BY 
    tc.total_customer_spent DESC, sp.avg_supply_cost ASC;