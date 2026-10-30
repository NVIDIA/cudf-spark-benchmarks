WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_return_quantity,
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
    GROUP BY 
        r.r_name
),
RankedSales AS (
    SELECT 
        region_name, 
        total_sales, 
        total_return_quantity,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
),
FilteredSales AS (
    SELECT 
        *,
        CASE 
            WHEN total_sales IS NULL THEN 'NULL Sales'
            WHEN total_sales = 0 THEN 'No Sales'
            ELSE 'Active Sales'
        END AS sales_status
    FROM 
        RankedSales
)
SELECT 
    fs.region_name,
    fs.total_sales,
    fs.total_return_quantity,
    fs.order_count,
    fs.sales_rank,
    fs.sales_status
FROM 
    FilteredSales fs
WHERE 
    fs.sales_rank <= 5
    OR (fs.total_sales IS NULL AND fs.order_count > 0)
UNION ALL
SELECT 
    'TOTAL' AS region_name,
    SUM(total_sales) AS total_sales,
    SUM(total_return_quantity) AS total_return_quantity,
    SUM(order_count) AS order_count,
    NULL AS sales_rank,
    'Aggregate' AS sales_status
FROM 
    FilteredSales
WHERE 
    sales_status = 'Active Sales'
HAVING 
    COUNT(region_name) > 0 
ORDER BY 
    total_sales DESC NULLS LAST;
