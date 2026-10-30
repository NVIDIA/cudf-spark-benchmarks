WITH RegionalSales AS (
    SELECT 
        r.r_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS region_rank
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
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_shipdate > '1997-01-01' 
        AND l.l_shipdate <= cast('1998-10-01' as date)
        AND o.o_orderstatus = 'F'
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    r_name,
    total_sales,
    order_count,
    CASE 
        WHEN total_sales > (SELECT AVG(total_sales) FROM RegionalSales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_performance
FROM 
    RegionalSales
WHERE 
    region_rank <= 5
ORDER BY 
    total_sales DESC;