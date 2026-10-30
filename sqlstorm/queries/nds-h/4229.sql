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
    WHERE o.o_orderstatus = 'O' 
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        ss.total_sales,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM supplier s
    JOIN SupplierSales ss ON s.s_suppkey = ss.s_suppkey
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.total_sales,
    ts.order_count,
    CASE 
        WHEN ts.sales_rank <= 10 THEN 'Top Supplier'
        ELSE 'Regular Supplier' 
    END AS supplier_type,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COALESCE(n.n_comment, 'No Comment') AS nation_comment
FROM TopSuppliers ts
LEFT JOIN supplier s ON ts.s_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE ts.total_sales > 100000
ORDER BY ts.total_sales DESC, ts.s_name;
