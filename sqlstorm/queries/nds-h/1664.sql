
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
        s.s_nationkey,
        COUNT(*) AS supplier_count,
        MAX(ss.total_sales) AS max_sales
    FROM 
        SupplierSales ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.sales_rank <= 5
    GROUP BY 
        s.s_nationkey
),
Regions AS (
    SELECT 
        r.r_regionkey, 
        r.r_name, 
        COALESCE(ts.supplier_count, 0) AS supplier_count,
        COALESCE(ts.max_sales, 0) AS max_sales
    FROM 
        region r
    LEFT JOIN 
        TopSuppliers ts ON r.r_regionkey = ts.s_nationkey
)
SELECT 
    r.r_name,
    r.supplier_count,
    r.max_sales,
    CASE 
        WHEN r.max_sales > 1000000 THEN 'High Performance'
        WHEN r.max_sales BETWEEN 500000 AND 1000000 THEN 'Medium Performance'
        ELSE 'Low Performance' 
    END AS performance_category
FROM 
    Regions r
WHERE 
    r.max_sales IS NOT NULL OR r.supplier_count > 0
ORDER BY 
    r.max_sales DESC, r.r_name;
