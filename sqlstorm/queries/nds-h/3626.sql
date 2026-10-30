WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
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
        AND o.o_orderdate < '1997-02-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales,
        ss.total_orders,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        supplier s
    LEFT JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
)
SELECT 
    t.s_suppkey,
    t.s_name,
    COALESCE(t.total_sales, 0) AS total_sales,
    COALESCE(t.total_orders, 0) AS total_orders,
    r.r_name AS region_name,
    CASE 
        WHEN t.sales_rank <= 10 THEN 'Top Supplier'
        ELSE 'Regular Supplier'
    END AS supplier_quality
FROM 
    TopSuppliers t
LEFT JOIN 
    supplier s ON t.s_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    (t.total_sales IS NOT NULL OR t.total_orders IS NOT NULL);