WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        r.r_name
), AverageSales AS (
    SELECT 
        AVG(total_revenue) AS avg_revenue,
        AVG(order_count) AS avg_orders
    FROM 
        RegionalSales
)
SELECT 
    r.region_name,
    r.total_revenue,
    a.avg_revenue,
    r.order_count,
    a.avg_orders,
    (r.total_revenue - a.avg_revenue) / a.avg_revenue * 100 AS revenue_variance_percentage
FROM 
    RegionalSales r, AverageSales a
ORDER BY 
    revenue_variance_percentage DESC
LIMIT 10;