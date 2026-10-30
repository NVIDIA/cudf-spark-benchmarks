
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' 
        AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, 
        o.o_orderdate, 
        c.c_nationkey
),
order_revenue AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.c_nationkey,
        RANK() OVER (PARTITION BY r.c_nationkey ORDER BY r.revenue DESC) AS revenue_rank,
        r.revenue
    FROM 
        ranked_orders r
)
SELECT 
    n.n_name,
    SUM(o.revenue) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    order_revenue o
JOIN 
    nation n ON o.c_nationkey = n.n_nationkey
WHERE 
    o.revenue_rank <= 10
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC;
