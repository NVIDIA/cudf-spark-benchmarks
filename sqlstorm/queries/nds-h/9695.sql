WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        r.r_name AS region_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
TopOrders AS (
    SELECT 
        order_rank,
        o_orderkey,
        o_orderdate,
        o_totalprice,
        c_name,
        region_name
    FROM 
        RankedOrders
    WHERE 
        order_rank <= 5
)
SELECT 
    region_name,
    COUNT(*) AS num_orders,
    AVG(o_totalprice) AS avg_order_value,
    SUM(o_totalprice) AS total_sales,
    MAX(o_totalprice) AS highest_order_value,
    MIN(o_totalprice) AS lowest_order_value
FROM 
    TopOrders
GROUP BY 
    region_name
ORDER BY 
    total_sales DESC;
