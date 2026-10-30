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
        o.o_orderstatus = 'O' 
        AND l.l_shipdate >= DATE '1996-01-01' 
    GROUP BY 
        s.s_suppkey, s.s_name
), TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
)
SELECT 
    sp.s_name,
    COALESCE(r.r_name, 'Unknown') AS region_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(COALESCE(ps.ps_availqty, 0)) AS total_available_qty
FROM 
    TopSuppliers sp
LEFT JOIN 
    supplier s ON sp.s_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
WHERE 
    sp.sales_rank <= 10
GROUP BY 
    sp.s_name, r.r_name
HAVING 
    SUM(COALESCE(ps.ps_availqty, 0)) > 1000
ORDER BY 
    customer_count DESC, total_available_qty DESC;