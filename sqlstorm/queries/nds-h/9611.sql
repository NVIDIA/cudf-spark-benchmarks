WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS rank_order
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
        n.n_name AS nation_name,
        n.n_regionkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        lineitem l ON ro.o_orderkey = l.l_orderkey
    JOIN 
        nation n ON ro.c_nationkey = n.n_nationkey
    WHERE 
        ro.rank_order <= 10
    GROUP BY 
        ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, ro.c_name, n.n_name, n.n_regionkey
),
FinalReport AS (
    SELECT 
        r.r_name AS region_name,
        ro.nation_name,
        COUNT(ro.o_orderkey) AS count_orders,
        SUM(ro.total_revenue) AS total_region_revenue
    FROM 
        RecentOrders ro
    JOIN 
        region r ON ro.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_name, ro.nation_name
)
SELECT 
    region_name,
    nation_name,
    count_orders,
    total_region_revenue,
    RANK() OVER (PARTITION BY region_name ORDER BY total_region_revenue DESC) AS revenue_rank
FROM 
    FinalReport
ORDER BY 
    region_name, revenue_rank;
