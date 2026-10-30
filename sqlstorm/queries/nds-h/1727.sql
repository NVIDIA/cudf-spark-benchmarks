WITH RegionSales AS (
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
),
RankedSales AS (
    SELECT 
        r_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionSales
)
SELECT 
    r.r_name,
    COALESCE(rs.total_sales, 0) AS total_sales,
    CASE 
        WHEN rs.sales_rank IS NOT NULL THEN 'Ranked'
        ELSE 'Unranked' 
    END AS rank_status
FROM 
    region r
LEFT JOIN 
    RankedSales rs ON r.r_name = rs.r_name
WHERE 
    r.r_comment IS NOT NULL
ORDER BY 
    r.r_name;
