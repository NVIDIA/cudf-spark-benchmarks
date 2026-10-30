
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01' 
        AND o.o_orderdate < '1997-01-01'
    GROUP BY 
        s.s_suppkey, 
        s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        n.n_name,
        ss.s_suppkey,
        ss.total_sales,
        ss.order_count,
        ss.sales_rank
    FROM 
        SupplierSales ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        ss.sales_rank <= 5
)
SELECT 
    t.n_name AS nation_name,
    COUNT(t.s_suppkey) AS top_supplier_count,
    AVG(t.total_sales) AS avg_sales
FROM 
    TopSuppliers t
GROUP BY 
    t.n_name
HAVING 
    AVG(t.total_sales) > (
        SELECT 
            AVG(total_sales)
        FROM 
            TopSuppliers
    )
ORDER BY 
    avg_sales DESC;
