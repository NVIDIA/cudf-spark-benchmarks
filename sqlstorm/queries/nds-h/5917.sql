WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
top_n_orders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.total_revenue
    FROM 
        ranked_orders r
    WHERE 
        r.revenue_rank <= 10
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    c.c_name,
    s.s_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_extended_price
FROM 
    top_n_orders t
JOIN 
    orders o ON t.o_orderkey = o.o_orderkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
GROUP BY 
    o.o_orderkey, o.o_orderdate, c.c_name, s.s_name
ORDER BY 
    o.o_orderdate, total_extended_price DESC
LIMIT 100;