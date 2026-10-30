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
    WHERE o.o_orderstatus = 'F' 
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM supplier s
    JOIN SupplierSales ss ON s.s_suppkey = ss.s_suppkey
)
SELECT 
    ts.s_name,
    COALESCE(ss.total_sales, 0) AS sales_total,
    CASE 
        WHEN ss.order_count IS NULL THEN 'No Orders'
        ELSE CONCAT('Orders: ', ss.order_count)
    END AS order_info,
    r.r_name AS region_name
FROM TopSuppliers ts
LEFT JOIN SupplierSales ss ON ts.s_suppkey = ss.s_suppkey
LEFT JOIN supplier s ON ts.s_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE ts.sales_rank <= 10
ORDER BY ts.sales_rank;
