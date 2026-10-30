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
        o.o_orderdate >= '1997-01-01'
        AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s_suppkey,
        s_name,
        total_sales,
        order_count,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SupplierSales
)
SELECT 
    t.s_suppkey,
    t.s_name,
    t.total_sales,
    t.order_count,
    CASE 
        WHEN t.order_count > 5 THEN 'High'
        WHEN t.order_count BETWEEN 1 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS order_intensity,
    r.r_name AS region_name
FROM 
    TopSuppliers t
LEFT OUTER JOIN 
    supplier s ON t.s_suppkey = s.s_suppkey
LEFT OUTER JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT OUTER JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.total_sales DESC;