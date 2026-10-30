WITH ranked_orders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders AS o
    JOIN 
        lineitem AS l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer AS c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
        AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, c.c_mktsegment
),
top_customers AS (
    SELECT 
        c.c_name, 
        c.c_mktsegment, 
        SUM(lo.revenue) AS total_revenue
    FROM 
        ranked_orders AS lo
    JOIN 
        orders AS o ON lo.o_orderkey = o.o_orderkey
    JOIN 
        customer AS c ON o.o_custkey = c.c_custkey
    WHERE 
        lo.revenue_rank <= 10
    GROUP BY 
        c.c_name, c.c_mktsegment
)
SELECT 
    c.c_name,
    c.c_mktsegment,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(lo.total_revenue) AS aggregated_revenue
FROM 
    top_customers AS lo
JOIN 
    customer AS c ON lo.c_name = c.c_name AND lo.c_mktsegment = c.c_mktsegment
JOIN 
    orders AS o ON o.o_custkey = c.c_custkey
GROUP BY 
    c.c_name, c.c_mktsegment
ORDER BY 
    aggregated_revenue DESC
LIMIT 20;