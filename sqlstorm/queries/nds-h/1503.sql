WITH SupplierSales AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name,
        ss.total_sales,
        DENSE_RANK() OVER (PARTITION BY r.r_regionkey ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        SupplierSales ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT ts.s_suppkey) AS supplier_count,
    AVG(ts.total_sales) AS avg_sales,
    MAX(ts.total_sales) AS max_sales,
    MIN(ts.total_sales) AS min_sales
FROM 
    TopSuppliers ts
JOIN 
    region r ON ts.r_name = r.r_name
WHERE 
    ts.sales_rank <= 3
GROUP BY 
    r.r_name
ORDER BY 
    r.r_name;
