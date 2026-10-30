WITH  RegionSales AS (
    SELECT 
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
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
    GROUP BY 
        r.r_name

    UNION ALL

    SELECT 
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
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
    WHERE
        l.l_shipdate > cast('1998-10-01' as date) - INTERVAL '6 months'
    GROUP BY 
        r.r_name
),
RankedSales AS (
    SELECT 
        r.r_name,
        SUM(ls.total_sales) AS region_total_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(ls.total_sales) DESC) AS sales_rank
    FROM 
        region r
    LEFT JOIN 
        RegionSales ls ON r.r_name = ls.r_name
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name,
    COALESCE(rs.region_total_sales, 0.00) AS total_sales,
    CASE 
        WHEN COALESCE(rs.region_total_sales, 0.00) > 1000000 THEN 'High'
        WHEN COALESCE(rs.region_total_sales, 0.00) BETWEEN 500000 AND 1000000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    region r
LEFT JOIN 
    RankedSales rs ON r.r_name = rs.r_name
ORDER BY 
    rs.sales_rank;