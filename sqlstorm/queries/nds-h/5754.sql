WITH region_supplier AS (
    SELECT 
        r.r_name AS region_name,
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name, s.s_suppkey, s.s_name
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
),
top_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.total_spent
    FROM 
        customer_orders c
    ORDER BY 
        c.total_spent DESC
    LIMIT 5
)
SELECT 
    rs.region_name,
    rs.s_name AS supplier_name,
    tc.c_name AS top_customer,
    tc.total_spent
FROM 
    region_supplier rs
JOIN 
    top_customers tc ON rs.total_supply_cost > (SELECT AVG(ps_supplycost) FROM partsupp ps);
