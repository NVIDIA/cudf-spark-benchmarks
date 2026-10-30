WITH customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        c.c_custkey, c.c_name
), supplier_parts AS (
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
), regional_summary AS (
    SELECT 
        r.r_name,
        SUM(co.total_spent) AS total_revenue,
        COUNT(DISTINCT co.c_custkey) AS unique_customers,
        AVG(co.avg_order_value) AS avg_order_value_per_customer
    FROM 
        customer_orders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name,
    r.total_revenue,
    r.unique_customers,
    r.avg_order_value_per_customer,
    sp.total_supply_cost
FROM 
    regional_summary r
LEFT JOIN 
    (SELECT 
         r.r_name,
         SUM(sp.total_supply_cost) AS total_supply_cost
     FROM 
         supplier_parts sp
     JOIN 
         nation n ON sp.s_suppkey = n.n_nationkey
     JOIN 
         region r ON n.n_regionkey = r.r_regionkey
     GROUP BY 
         r.r_name) sp ON r.r_name = sp.r_name
ORDER BY 
    r.total_revenue DESC;