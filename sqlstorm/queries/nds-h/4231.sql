WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
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
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        r.r_name
),
RankedRegions AS (
    SELECT 
        region_name,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
),
AverageOrder AS (
    SELECT 
        AVG(total_sales) AS avg_sales
    FROM 
        RankedRegions
    WHERE 
        sales_rank <= 5
)
SELECT 
    r.region_name,
    r.total_sales,
    r.order_count,
    CASE 
        WHEN r.total_sales > a.avg_sales THEN 'Above Average'
        WHEN r.total_sales < a.avg_sales THEN 'Below Average'
        ELSE 'Average'
    END AS sales_performance
FROM 
    RankedRegions r
CROSS JOIN 
    AverageOrder a
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.total_sales DESC;