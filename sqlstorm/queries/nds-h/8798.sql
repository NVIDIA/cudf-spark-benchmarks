WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
top_n_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(ro.total_revenue) AS customer_revenue
    FROM 
        customer c
    JOIN 
        ranked_orders ro ON c.c_custkey = ro.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    ORDER BY 
        customer_revenue DESC
    LIMIT 10
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    tc.customer_revenue,
    n.n_name AS customer_nation,
    r.r_name AS customer_region
FROM 
    top_n_customers tc
JOIN 
    nation n ON tc.c_custkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
ORDER BY 
    tc.customer_revenue DESC;