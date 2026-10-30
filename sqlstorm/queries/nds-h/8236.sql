
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank,
        o.o_custkey
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, o.o_custkey
),
TopOrders AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT ro.o_orderkey) AS order_count,
        AVG(ro.total_revenue) AS avg_revenue
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.order_rank <= 5
    GROUP BY 
        r.r_name
)
SELECT 
    region_name,
    order_count,
    avg_revenue,
    RANK() OVER (ORDER BY avg_revenue DESC) AS revenue_rank
FROM 
    TopOrders
ORDER BY 
    revenue_rank;
