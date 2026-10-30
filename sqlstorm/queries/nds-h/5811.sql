
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        r.r_name AS region_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY o.o_totalprice DESC) AS rank_in_region
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
TopRegionOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.c_name,
        o.region_name
    FROM 
        RankedOrders o
    WHERE 
        o.rank_in_region <= 5
)
SELECT 
    t.region_name,
    COUNT(*) AS order_count,
    AVG(t.o_totalprice) AS avg_order_price,
    SUM(t.o_totalprice) AS total_revenue
FROM 
    TopRegionOrders t
GROUP BY 
    t.region_name
ORDER BY 
    total_revenue DESC;
