
WITH SupplierSales AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, ss.total_sales, ss.total_orders, 
           RANK() OVER (PARTITION BY r.r_name ORDER BY ss.total_sales DESC) AS sales_rank
    FROM SupplierSales ss
    JOIN supplier s ON ss.s_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT rs.s_suppkey, rs.s_name, COALESCE(rs.total_sales, 0) AS total_sales, COALESCE(rs.total_orders, 0) AS total_orders, rs.sales_rank
FROM RankedSuppliers rs
WHERE rs.sales_rank <= 3
ORDER BY rs.sales_rank ASC, total_sales DESC;
