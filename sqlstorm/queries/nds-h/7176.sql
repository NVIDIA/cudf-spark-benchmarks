WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND 
        o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, c.c_name, o.o_orderdate, o.o_orderstatus
),
high_value_orders AS (
    SELECT 
        ro.o_orderkey,
        ro.c_name,
        ro.total_revenue,
        ro.o_orderdate,
        ro.order_rank
    FROM 
        ranked_orders ro
    WHERE 
        ro.order_rank <= 5
)
SELECT 
    hvo.o_orderkey,
    hvo.c_name,
    hvo.total_revenue,
    hvo.o_orderdate
FROM 
    high_value_orders hvo
ORDER BY 
    hvo.total_revenue DESC;