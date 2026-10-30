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
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
), RankedSuppliers AS (
    SELECT 
        s.*, 
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SupplierSales s
), AverageSales AS (
    SELECT 
        AVG(total_sales) AS avg_sales 
    FROM 
        SupplierSales
)
SELECT 
    r.r_name, 
    ns.s_name, 
    ns.total_sales, 
    ns.order_count, 
    CASE 
        WHEN ns.total_sales > (SELECT avg_sales FROM AverageSales) THEN 'Above Average' 
        ELSE 'Below Average' 
    END AS sales_category
FROM 
    RankedSuppliers ns
LEFT JOIN 
    supplier sup ON ns.s_suppkey = sup.s_suppkey
LEFT JOIN 
    nation n ON sup.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    ns.sales_rank <= 10
ORDER BY 
    ns.total_sales DESC;