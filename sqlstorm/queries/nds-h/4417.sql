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
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank,
        RANK() OVER (ORDER BY ss.order_count DESC) AS order_rank
    FROM 
        supplier s
    LEFT JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        COALESCE(rs.total_sales, 0) AS total_sales,
        COALESCE(rs.order_count, 0) AS order_count,
        rs.sales_rank,
        rs.order_rank
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.sales_rank <= 10 OR rs.order_rank <= 10
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.total_sales,
    ts.order_count
FROM 
    TopSuppliers ts
ORDER BY 
    ts.total_sales DESC, ts.order_count DESC;