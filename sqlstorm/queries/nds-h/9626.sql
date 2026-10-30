WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        r.r_name AS region_name,
        n.n_name AS nation_name,
        c.c_name AS customer_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
top_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.region_name,
        o.nation_name,
        o.customer_name
    FROM 
        ranked_orders o
    WHERE 
        o.rank <= 10
)
SELECT 
    t.region_name,
    t.nation_name,
    COUNT(t.o_orderkey) AS total_orders,
    SUM(t.o_totalprice) AS total_revenue,
    AVG(t.o_totalprice) AS avg_order_value
FROM 
    top_orders t
GROUP BY 
    t.region_name, 
    t.nation_name
ORDER BY 
    total_revenue DESC;