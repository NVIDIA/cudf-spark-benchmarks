WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        c.c_nationkey,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'F'
),
FilteredOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.c_name,
        ro.o_totalprice
    FROM 
        RankedOrders ro
    WHERE 
        ro.rn <= 5
),
AggregateData AS (
    SELECT 
        n.n_name,
        COUNT(fo.o_orderkey) AS total_orders,
        SUM(fo.o_totalprice) AS total_revenue
    FROM 
        FilteredOrders fo
    JOIN 
        customer c ON fo.c_name = c.c_name
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    n.n_name,
    ad.total_orders,
    ad.total_revenue,
    RANK() OVER (ORDER BY ad.total_revenue DESC) AS revenue_rank
FROM 
    AggregateData ad
JOIN 
    nation n ON ad.n_name = n.n_name
ORDER BY 
    ad.total_revenue DESC;
