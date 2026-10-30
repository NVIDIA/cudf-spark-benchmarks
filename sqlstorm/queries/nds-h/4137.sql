WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS num_orders,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(lp.l_extendedprice * (1 - lp.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem lp ON ps.ps_partkey = lp.l_partkey
    JOIN 
        orders o ON lp.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        s.s_nationkey,
        s.s_suppkey,
        s.s_name
    FROM 
        supplier s
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        ss.sales_rank <= 5
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT ts.s_suppkey) AS num_top_suppliers,
    SUM(COALESCE(ss.total_sales, 0)) AS total_sales_amount
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    TopSuppliers ts ON n.n_nationkey = ts.s_nationkey
LEFT JOIN 
    SupplierSales ss ON ts.s_suppkey = ss.s_suppkey
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    r.r_name, total_sales_amount DESC;