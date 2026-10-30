WITH RegionSales AS (
    SELECT 
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY 
        r.r_name
),

TopRegions AS (
    SELECT
        r_name,
        total_sales,
        order_count
    FROM 
        RegionSales
    WHERE 
        sales_rank <= 5
)

SELECT 
    r_name,
    total_sales,
    order_count,
    first_value(total_sales) OVER (ORDER BY total_sales DESC) AS max_sales,
    CASE 
        WHEN total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Available'
    END AS sales_status
FROM 
    TopRegions
ORDER BY 
    total_sales DESC;