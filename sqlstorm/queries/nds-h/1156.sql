
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
        l.l_shipdate >= '1996-01-01' AND l.l_shipdate < '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s_suppkey,
        s_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SupplierSales
),
RegionInfo AS (
    SELECT 
        n.n_nationkey,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    ri.region_name,
    ri.nation_name,
    ts.s_name,
    COALESCE(ts.total_sales, 0) AS total_sales,
    CASE 
        WHEN ts.total_sales IS NULL THEN 'No Sales'
        WHEN ts.total_sales < 10000 THEN 'Low Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    RegionInfo ri
LEFT JOIN 
    TopSuppliers ts ON ri.n_nationkey = ts.s_suppkey
ORDER BY 
    ri.region_name, sales_category DESC;
