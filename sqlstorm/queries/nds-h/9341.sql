WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
)

SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    SUM(ro.o_totalprice) AS total_revenue,
    AVG(ro.o_totalprice) AS avg_order_value
FROM 
    RankedOrders ro
JOIN 
    nation n ON ro.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    ro.order_rank <= 5
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    total_revenue DESC;
