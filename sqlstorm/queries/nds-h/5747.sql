WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1996-12-31'
),
top_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
details AS (
    SELECT 
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1996-12-31'
    GROUP BY 
        c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT 
    d.c_name,
    COUNT(DISTINCT d.o_orderkey) AS number_of_orders,
    SUM(d.revenue) AS total_revenue,
    MAX(r.order_rank) AS latest_order_rank
FROM 
    details d
JOIN 
    ranked_orders r ON d.o_orderkey = r.o_orderkey
GROUP BY 
    d.c_name
ORDER BY 
    total_revenue DESC,
    number_of_orders DESC
LIMIT 20;