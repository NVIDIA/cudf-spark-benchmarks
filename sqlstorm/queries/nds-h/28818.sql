WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) as order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
RecentOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 5
),
LineItemDetails AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
        COUNT(lo.l_linenumber) AS line_count
    FROM 
        lineitem lo
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.c_name,
    lod.total_revenue,
    lod.line_count
FROM 
    RecentOrders ro
LEFT JOIN 
    LineItemDetails lod ON ro.o_orderkey = lod.l_orderkey
ORDER BY 
    ro.o_orderdate DESC, 
    ro.o_orderkey;
