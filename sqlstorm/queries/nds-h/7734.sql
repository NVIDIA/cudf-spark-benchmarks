WITH Revenue AS (
    SELECT 
        c.c_name AS customer_name,
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND 
        o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        c.c_name, n.n_name
),
RankedRevenue AS (
    SELECT 
        customer_name, 
        nation_name, 
        total_revenue,
        RANK() OVER (PARTITION BY nation_name ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        Revenue
)
SELECT 
    nation_name, 
    customer_name, 
    total_revenue
FROM 
    RankedRevenue
WHERE 
    revenue_rank <= 10
ORDER BY 
    nation_name, 
    total_revenue DESC;