
WITH SupplierOrders AS (
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
        AND l.l_shipdate >= DATE '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        so.total_sales,
        RANK() OVER (ORDER BY so.total_sales DESC) AS sales_rank
    FROM 
        SupplierOrders so
    JOIN 
        supplier s ON so.s_suppkey = s.s_suppkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    SUM(rs.total_sales) AS total_supplier_sales,
    AVG(rs.total_sales) AS avg_supplier_sales
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
WHERE 
    r.r_comment IS NOT NULL 
    AND n.n_comment IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    SUM(rs.total_sales) > 10000
ORDER BY 
    nation_count DESC, total_supplier_sales DESC;
