WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND 
        o.o_orderdate < DATE '1997-10-01' 
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(ss.total_sales, 0) AS total_sales,
        ss.order_count,
        ss.sales_rank,
        r.r_name
    FROM 
        supplier s
    LEFT JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    r.r_name AS region,
    COUNT(*) AS supplier_count,
    SUM(r.total_sales) AS total_region_sales,
    AVG(CASE WHEN r.sales_rank IS NOT NULL THEN r.total_sales END) AS avg_sales_top_suppliers
FROM 
    RankedSuppliers r
WHERE 
    r.sales_rank <= 5 OR r.sales_rank IS NULL
GROUP BY 
    r.r_name
ORDER BY 
    total_region_sales DESC;