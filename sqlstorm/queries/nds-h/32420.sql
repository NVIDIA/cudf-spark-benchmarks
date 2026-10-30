WITH  RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        n.n_name
    UNION ALL
    SELECT 
        r.r_name AS nation_name,
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
        r.r_name IS NOT NULL
    GROUP BY 
        r.r_name
),
TotalSales AS (
    SELECT 
        nation_name,
        SUM(total_sales) AS aggregated_sales
    FROM 
        RegionalSales
    GROUP BY 
        nation_name
),
RankedSales AS (
    SELECT 
        nation_name,
        aggregated_sales,
        RANK() OVER (ORDER BY aggregated_sales DESC) AS rank_position
    FROM 
        TotalSales
)
SELECT 
    r.nation_name,
    r.aggregated_sales,
    CASE 
        WHEN r.rank_position <= 5 THEN 'Top 5'
        ELSE 'Others'
    END AS sales_category
FROM 
    RankedSales r
WHERE 
    r.aggregated_sales IS NOT NULL
ORDER BY 
    r.aggregated_sales DESC;

