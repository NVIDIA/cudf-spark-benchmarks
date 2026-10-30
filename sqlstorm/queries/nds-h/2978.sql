
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank,
        s.s_nationkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_sales,
        ss.order_count,
        TRIM(n.n_name) AS nation_name
    FROM 
        SupplierSales ss
    JOIN 
        nation n ON ss.s_nationkey = n.n_nationkey
    WHERE 
        ss.sales_rank <= 5
)
SELECT 
    ts.s_name,
    ts.total_sales,
    ts.order_count,
    CASE 
        WHEN ts.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Made'
    END AS sales_status,
    COALESCE(REPLACE(ts.nation_name, ' ', '_'), 'Unknown') AS formatted_nation
FROM 
    TopSuppliers ts
ORDER BY 
    ts.total_sales DESC
LIMIT 10;
