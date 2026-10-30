WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) as order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
top_orders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.c_name
    FROM 
        ranked_orders r
    WHERE 
        r.order_rank <= 5
),
product_details AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_products
    FROM 
        lineitem l
    JOIN 
        top_orders t ON l.l_orderkey = t.o_orderkey
    GROUP BY 
        l.l_orderkey
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.c_name,
    p.total_revenue,
    p.unique_products
FROM 
    top_orders t
JOIN 
    product_details p ON t.o_orderkey = p.l_orderkey
ORDER BY 
    t.o_orderdate DESC, p.total_revenue DESC;
