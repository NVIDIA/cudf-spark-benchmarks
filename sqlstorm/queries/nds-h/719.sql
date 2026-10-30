WITH RegionalSales AS (
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
    WHERE 
        l.l_shipdate >= '1996-01-01' 
        AND l.l_shipdate < '1997-01-01'
    GROUP BY 
        n.n_name
),
RankedSales AS (
    SELECT 
        nation_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
)
SELECT 
    r.r_name AS region_name,
    COALESCE(rs.nation_name, 'No Sales') AS nation_name,
    COALESCE(rs.total_sales, 0) AS total_sales,
    CASE 
        WHEN rs.sales_rank IS NULL THEN 'Not Ranked'
        ELSE CAST(rs.sales_rank AS STRING)
    END AS sales_rank
FROM 
    region r
LEFT JOIN 
    RankedSales rs ON r.r_name = rs.nation_name
WHERE 
    r.r_regionkey IN (SELECT DISTINCT n.n_regionkey FROM nation n)
ORDER BY 
    total_sales DESC NULLS LAST;