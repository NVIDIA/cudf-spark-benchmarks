
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
        o.o_orderstatus = 'O' 
        AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
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
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_sales,
        rs.total_orders
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.sales_rank <= 10
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(ts.total_sales, 0) AS supplier_total_sales,
    COALESCE(ts.total_orders, 0) AS supplier_total_orders,
    COUNT(DISTINCT ts.s_suppkey) AS unique_suppliers
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, ts.total_sales, ts.total_orders
ORDER BY 
    supplier_total_sales DESC,
    p.p_name ASC;
