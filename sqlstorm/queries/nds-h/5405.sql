WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS OrderRank
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
        ro.c_name,
        n.n_name AS nation_name
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON ro.c_nationkey = n.n_nationkey
    WHERE 
        ro.OrderRank <= 5
),
LineItemSummary AS (
    SELECT 
        lo.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM 
        lineitem li
    JOIN 
        orders lo ON li.l_orderkey = lo.o_orderkey
    GROUP BY 
        lo.o_orderkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.c_name,
    ro.nation_name,
    ls.total_revenue
FROM 
    RecentOrders ro
LEFT JOIN 
    LineItemSummary ls ON ro.o_orderkey = ls.o_orderkey
ORDER BY 
    ro.o_orderdate DESC, 
    total_revenue DESC;
