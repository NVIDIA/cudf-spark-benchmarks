WITH  TotalRevenue AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(l_extendedprice) FROM lineitem)
),
MonthlySummary AS (
    SELECT 
        DATE_TRUNC('month', o.o_orderdate) AS order_month,
        SUM(tr.total_order_revenue) AS total_revenue_per_month
    FROM 
        TotalRevenue tr
    JOIN 
        orders o ON tr.o_orderkey = o.o_orderkey
    GROUP BY 
        order_month
),
RegionSales AS (
    SELECT 
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        r.r_name
),
HighestSale AS (
    SELECT 
        r.r_name,
        rSales.total_sales,
        ROW_NUMBER() OVER (ORDER BY rSales.total_sales DESC) AS sales_rank
    FROM 
        RegionSales rSales
    JOIN 
        region r ON rSales.r_name = r.r_name
)
SELECT 
    ms.order_month,
    COALESCE(hs.r_name, 'No sales') AS region_name,
    COALESCE(hs.total_sales, 0) AS highest_region_sales,
    ms.total_revenue_per_month,
    ((ms.total_revenue_per_month - COALESCE(hs.total_sales, 0)) / NULLIF(ms.total_revenue_per_month, 0)) * 100 AS revenue_difference_percentage
FROM 
    MonthlySummary ms
LEFT JOIN 
    HighestSale hs ON ms.order_month = DATE_TRUNC('month', cast('1998-10-01' as date)) AND hs.sales_rank = 1
ORDER BY 
    ms.order_month DESC;