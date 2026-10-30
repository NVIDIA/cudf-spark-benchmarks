WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
        l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        n.n_nationkey, n.n_name
),
HighestSales AS (
    SELECT 
        nation_name, 
        total_sales 
    FROM 
        RegionalSales 
    WHERE 
        sales_rank <= 3
)
SELECT 
    r.r_name AS region_name, 
    h.nation_name,
    h.total_sales,
    CASE 
        WHEN h.total_sales > 500000 THEN 'High'
        WHEN h.total_sales BETWEEN 250000 AND 500000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    HighestSales h ON n.n_name = h.nation_name
ORDER BY 
    r.r_name, h.total_sales DESC NULLS LAST;