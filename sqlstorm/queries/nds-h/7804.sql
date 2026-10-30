WITH SupplierSales AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY s.s_suppkey, s.s_name
),
RankedSales AS (
    SELECT s.s_suppkey, s.s_name, ss.total_sales,
           RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM SupplierSales ss
    JOIN supplier s ON ss.s_suppkey = s.s_suppkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, rs.total_sales
    FROM RankedSales rs
    JOIN supplier s ON rs.s_suppkey = s.s_suppkey
    WHERE rs.sales_rank <= 10
)
SELECT ts.s_suppkey, ts.s_name, ts.total_sales, 
       COUNT(DISTINCT o.o_orderkey) AS total_orders, 
       AVG(o.o_totalprice) AS average_order_value
FROM TopSuppliers ts
LEFT JOIN partsupp ps ON ts.s_suppkey = ps.ps_suppkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
WHERE o.o_orderstatus = 'O'
GROUP BY ts.s_suppkey, ts.s_name, ts.total_sales
ORDER BY ts.total_sales DESC;