WITH RecursiveCTE AS (
    SELECT 
        n.n_name,
        r.r_name AS region,
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice * (1 - l.l_discount) END) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        r.r_comment LIKE '%specific%' 
        AND (o.o_orderdate IS NULL OR o.o_orderdate >= DATE '1996-01-01')
    GROUP BY 
        n.n_name, r.r_name
    HAVING 
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice * (1 - l.l_discount) END) IS NOT NULL
),
AggregatedSales AS (
    SELECT 
        region,
        SUM(total_sales) AS regional_sales,
        AVG(total_orders) AS avg_orders
    FROM 
        RecursiveCTE
    GROUP BY 
        region
)
SELECT 
    a.region,
    a.regional_sales,
    COALESCE(a.avg_orders, 0) AS avg_orders,
    CASE 
        WHEN a.regional_sales > 100000 THEN 'High'
        WHEN a.regional_sales BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    ROW_NUMBER() OVER (ORDER BY a.regional_sales DESC) AS rank
FROM 
    AggregatedSales a
WHERE 
    a.region IS NOT NULL
EXCEPT
SELECT 
    r_name AS region,
    0 AS regional_sales,
    0 AS avg_orders,
    'No sales' AS sales_category,
    ROW_NUMBER() OVER (ORDER BY r_name) AS rank
FROM 
    region
WHERE 
    r_name NOT IN (SELECT region FROM AggregatedSales)
ORDER BY 
    regional_sales DESC, region;