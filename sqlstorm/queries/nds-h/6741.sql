WITH RankedOrders AS (
    SELECT 
        o_orderkey,
        o_custkey,
        o_totalprice,
        o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC) AS OrderRank
    FROM 
        orders
    WHERE 
        o_orderdate >= DATE '1996-01-01'
),
AggregatedData AS (
    SELECT 
        c.c_name AS customer_name,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
        COUNT(DISTINCT ro.o_orderkey) AS total_orders
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON c.c_custkey = ro.o_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        lineitem lo ON ro.o_orderkey = lo.l_orderkey
    WHERE 
        ro.OrderRank <= 5
    GROUP BY 
        c.c_name, n.n_name, r.r_name
)
SELECT 
    nation_name,
    region_name,
    SUM(total_revenue) AS total_revenue_by_region,
    AVG(total_orders) AS average_orders_per_customer
FROM 
    AggregatedData
GROUP BY 
    nation_name, region_name
ORDER BY 
    total_revenue_by_region DESC
LIMIT 10;