WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
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
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        r.r_name
), TopRegions AS (
    SELECT 
        region_name, 
        total_sales, 
        order_count
    FROM 
        RegionalSales
    WHERE 
        sales_rank <= 5
)
SELECT 
    tr.region_name,
    tr.total_sales,
    tr.order_count,
    COALESCE(
        (SELECT AVG(total_sales) 
         FROM TopRegions), 
        0
    ) AS avg_sales,
    CASE 
        WHEN tr.total_sales > (SELECT AVG(total_sales) FROM TopRegions) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_comparison
FROM 
    TopRegions tr
ORDER BY 
    tr.total_sales DESC