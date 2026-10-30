WITH  RegionalSales AS (
    SELECT 
        n.n_name AS nation,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        n.n_name, n.n_nationkey
),
TopSales AS (
    SELECT 
        nation, 
        total_sales
    FROM 
        RegionalSales
    WHERE 
        sales_rank <= 3
),
RegionComments AS (
    SELECT 
        r.r_name,
        COUNT(*) AS nation_count,
        STRING_AGG(n.n_comment, '; ') AS comments
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_name
)
SELECT 
    t.nation,
    t.total_sales,
    rc.r_name,
    rc.nation_count,
    rc.comments,
    CASE 
        WHEN t.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Exist'
    END AS sales_status
FROM 
    TopSales t
LEFT JOIN 
    RegionComments rc ON rc.nation_count > 1
ORDER BY 
    t.total_sales DESC NULLS LAST
LIMIT 10;