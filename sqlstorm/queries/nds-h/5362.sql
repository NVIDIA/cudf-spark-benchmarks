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
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
top_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(ro.total_revenue) AS revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        ranked_orders ro ON o.o_orderkey = ro.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    ORDER BY 
        revenue DESC
    LIMIT 10
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS customer_total_spent,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_extendedprice) AS avg_lineitem_price,
    MAX(l.l_shipdate) AS last_order_date
FROM 
    top_customers tc
JOIN 
    orders o ON tc.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
GROUP BY 
    tc.c_custkey, tc.c_name
ORDER BY 
    customer_total_spent DESC;
