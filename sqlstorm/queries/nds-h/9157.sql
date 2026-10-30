WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
), RecentOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.o_orderstatus,
        ro.c_name,
        n.n_name AS nation_name
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON ro.c_nationkey = n.n_nationkey
    WHERE 
        ro.rn <= 5
), LineItemSummary AS (
    SELECT 
        lo.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        SUM(li.l_quantity) AS total_quantity
    FROM 
        lineitem li
    JOIN 
        orders lo ON li.l_orderkey = lo.o_orderkey
    GROUP BY 
        lo.o_orderkey
), FinalSummary AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.o_orderstatus,
        ro.c_name,
        ro.nation_name,
        COALESCE(ls.total_revenue, 0) AS total_revenue,
        COALESCE(ls.total_quantity, 0) AS total_quantity
    FROM 
        RecentOrders ro
    LEFT JOIN 
        LineItemSummary ls ON ro.o_orderkey = ls.o_orderkey
)
SELECT 
    f.o_orderkey,
    f.o_orderdate,
    f.o_totalprice,
    f.o_orderstatus,
    f.c_name,
    f.nation_name,
    f.total_revenue,
    f.total_quantity
FROM 
    FinalSummary f
ORDER BY 
    f.o_orderdate DESC, f.total_revenue DESC;
