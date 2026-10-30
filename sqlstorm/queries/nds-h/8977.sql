
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS unique_customers,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
TopRevenueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.total_revenue,
        ro.unique_customers,
        r.r_name AS region_name,
        n.n_name AS nation_name
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.o_orderkey = c.c_custkey
    JOIN 
        supplier s ON c.c_nationkey = s.s_nationkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.revenue_rank <= 10
)
SELECT 
    t.region_name,
    COUNT(DISTINCT t.o_orderkey) AS orders_count,
    SUM(t.total_revenue) AS total_revenue
FROM 
    TopRevenueOrders t
GROUP BY 
    t.region_name
ORDER BY 
    total_revenue DESC;
