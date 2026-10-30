WITH SupplierSales AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT 
        s.s_name, 
        ss.total_sales,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank,
        ROW_NUMBER() OVER (PARTITION BY ss.order_count ORDER BY ss.total_sales DESC) AS order_rank
    FROM SupplierSales ss
    JOIN supplier s ON ss.s_suppkey = s.s_suppkey
)
SELECT 
    rs.s_name,
    rs.total_sales,
    rs.order_count,
    CASE 
        WHEN rs.sales_rank <= 10 THEN 'Top Sellers'
        ELSE 'Others'
    END AS category,
    COALESCE((SELECT MAX(total_sales) FROM RankedSuppliers WHERE order_count = rs.order_count), 0) AS max_sales_for_order_count
FROM RankedSuppliers rs
WHERE rs.total_sales > (SELECT AVG(total_sales) FROM SupplierSales)
ORDER BY rs.total_sales DESC
LIMIT 20;