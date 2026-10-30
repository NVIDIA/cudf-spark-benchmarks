
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        c.c_name, 
        o.o_orderstatus, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' 
        AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, 
        c.c_name, 
        o.o_orderstatus
),
MinMaxRevenue AS (
    SELECT 
        MIN(total_revenue) AS min_revenue, 
        MAX(total_revenue) AS max_revenue
    FROM 
        RankedOrders
),
RevenueDistribution AS (
    SELECT 
        total_revenue, 
        COUNT(o_orderkey) AS order_count
    FROM 
        RankedOrders
    GROUP BY 
        total_revenue
)
SELECT 
    r.o_orderkey, 
    r.c_name, 
    r.o_orderstatus, 
    CASE 
        WHEN r.total_revenue < m.min_revenue THEN 'Low Revenue'
        WHEN r.total_revenue > m.max_revenue THEN 'High Revenue'
        ELSE 'Average Revenue'
    END AS revenue_category
FROM 
    RankedOrders r
JOIN 
    MinMaxRevenue m ON 1 = 1
JOIN 
    RevenueDistribution d ON r.total_revenue = d.total_revenue
ORDER BY 
    r.total_revenue DESC 
LIMIT 10;
