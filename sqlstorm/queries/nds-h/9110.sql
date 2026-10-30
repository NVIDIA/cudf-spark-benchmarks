
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey
),
top_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(r.total_revenue) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        ranked_orders r ON o.o_orderkey = r.o_orderkey
    WHERE 
        r.revenue_rank <= 5
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    c.c_name,
    c.total_spent,
    n.n_name AS nation_name,
    r.r_name AS region_name
FROM 
    top_customers c
JOIN 
    nation n ON c.c_custkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
ORDER BY 
    c.total_spent DESC
LIMIT 10;
