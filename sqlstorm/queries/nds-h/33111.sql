WITH  RegionalSales AS (
    SELECT 
        r.r_regionkey,
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
        r.r_regionkey, r.r_name
	
    UNION ALL
	
    SELECT 
        r.r_regionkey,
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
        l.l_shipdate > cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        r.r_regionkey, r.r_name
),
SalesWithRank AS (
    SELECT 
        r.r_name,
        rs.total_sales,
        RANK() OVER (ORDER BY rs.total_sales DESC) AS sales_rank
    FROM 
        RegionalSales rs
    JOIN 
        region r ON rs.r_regionkey = r.r_regionkey
)
SELECT 
    s.w_name,
    COALESCE(sr.total_sales, 0) AS total_sales,
    CASE 
        WHEN sr.sales_rank IS NOT NULL THEN 'Ranked'
        ELSE 'Not Ranked'
    END AS rank_status
FROM 
    (SELECT DISTINCT r_name AS w_name FROM region) s
LEFT JOIN 
    SalesWithRank sr ON s.w_name = sr.r_name
WHERE 
    COALESCE(sr.total_sales, 0) > 500000.00 
    OR sr.sales_rank IS NULL
ORDER BY 
    total_sales DESC, s.w_name;