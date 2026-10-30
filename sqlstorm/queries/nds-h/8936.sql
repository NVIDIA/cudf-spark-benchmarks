WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
), RecentTopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        n.n_name AS nation_name
    FROM 
        RankedOrders r
    JOIN 
        nation n ON r.c_nationkey = n.n_nationkey
    WHERE 
        r.rnk <= 10
), OrderLineStats AS (
    SELECT 
        r.o_orderkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_tax) AS avg_tax
    FROM 
        RecentTopOrders r
    JOIN 
        lineitem l ON r.o_orderkey = l.l_orderkey
    GROUP BY 
        r.o_orderkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ol.total_quantity,
    ol.total_revenue,
    ol.avg_tax,
    ro.nation_name
FROM 
    RecentTopOrders ro
JOIN 
    OrderLineStats ol ON ro.o_orderkey = ol.o_orderkey
ORDER BY 
    ro.o_orderdate DESC, ro.o_totalprice DESC
LIMIT 100;
