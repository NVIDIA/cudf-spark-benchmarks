WITH SupplierSales AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ss.total_sales
    FROM 
        supplier s
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        ss.sales_rank <= 5
),
RegionSummary AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COALESCE(SUM(ts.total_sales), 0) AS region_sales
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        TopSuppliers ts ON n.n_nationkey = ts.s_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    r.r_name,
    r.region_sales,
    ROUND(r.region_sales / NULLIF(SUM(r.region_sales) OVER (), 0) * 100, 2) AS sales_percentage,
    CASE 
        WHEN r.region_sales > 100000 THEN 'High Sales'
        WHEN r.region_sales BETWEEN 50000 AND 100000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    RegionSummary r
WHERE 
    r.region_sales > 0
ORDER BY 
    r.region_sales DESC;
