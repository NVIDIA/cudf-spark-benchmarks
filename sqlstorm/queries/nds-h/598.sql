WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        region r
    JOIN 
        nation n ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON p.p_partkey = ps.ps_partkey
    JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    JOIN 
        orders o ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        n.n_name, r.r_name
),
AggregatedSales AS (
    SELECT 
        region_name,
        SUM(total_sales) AS regional_total_sales,
        MAX(order_count) AS max_orders
    FROM 
        RegionalSales
    GROUP BY 
        region_name
),
SalesRanking AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY region_name ORDER BY regional_total_sales DESC) AS sales_rank
    FROM 
        AggregatedSales
)
SELECT 
    s.region_name,
    s.regional_total_sales,
    s.max_orders,
    COALESCE(s.sales_rank, 0) AS sales_rank,
    CASE 
        WHEN s.regional_total_sales > 1000000 THEN 'High Performer'
        WHEN s.regional_total_sales BETWEEN 500000 AND 1000000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    SalesRanking s
LEFT JOIN 
    RegionalSales r ON s.region_name = r.region_name
WHERE 
    s.max_orders IS NOT NULL
ORDER BY 
    s.regional_total_sales DESC;