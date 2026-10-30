WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1995-01-01' AND l.l_shipdate < DATE '1996-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RegionSales AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        SUM(S.total_sales) AS total_sales_region
    FROM 
        SupplierSales S
    JOIN 
        supplier supp ON S.s_suppkey = supp.s_suppkey
    JOIN 
        nation n ON supp.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_regionkey, r.r_name
),
RankedSales AS (
    SELECT 
        r.r_name,
        r.total_sales_region,
        RANK() OVER (ORDER BY r.total_sales_region DESC) AS sales_rank
    FROM 
        RegionSales r
)
SELECT 
    COALESCE(rs.r_name, 'Unknown Region') AS region_name,
    COALESCE(rs.total_sales_region, 0) AS total_sales,
    CASE 
        WHEN rs.sales_rank IS NULL THEN 'No Sales'
        ELSE CAST(rs.sales_rank AS STRING)
    END AS sales_rank
FROM 
    RankedSales rs
RIGHT JOIN 
    region r ON rs.r_name = r.r_name
WHERE 
    r.r_name IS NOT NULL
ORDER BY 
    total_sales DESC, region_name;