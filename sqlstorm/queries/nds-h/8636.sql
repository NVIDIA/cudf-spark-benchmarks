
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
top_revenue_orders AS (
    SELECT 
        o_orderkey,
        o_orderdate,
        revenue
    FROM 
        ranked_orders
    WHERE 
        order_rank <= 10
)
SELECT 
    c.c_name,
    c.c_address,
    n.n_name AS nation,
    r.r_name AS region,
    tor.revenue
FROM 
    top_revenue_orders tor
JOIN 
    orders o ON tor.o_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
ORDER BY 
    tor.revenue DESC;
