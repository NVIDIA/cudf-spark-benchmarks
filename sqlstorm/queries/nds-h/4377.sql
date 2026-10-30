WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        supplier s
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey
        JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SupplierSales
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    rs.s_name AS supplier_name,
    rs.total_sales,
    rs.total_orders,
    rs.avg_quantity
FROM 
    RankedSuppliers rs
    LEFT JOIN supplier s ON rs.s_suppkey = s.s_suppkey
    LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE 
    rs.sales_rank <= 10
    AND (rs.total_sales IS NOT NULL AND rs.total_orders > 5)
ORDER BY 
    r.r_name, n.n_name, rs.total_sales DESC;