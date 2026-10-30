
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name, 
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), 
TopSuppliers AS (
    SELECT *
    FROM RankedSuppliers
    WHERE rank <= 5
), 
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, l.l_partkey, l.l_quantity, l.l_extendedprice, l.l_discount,
           l.l_shipdate, ts.s_suppkey, ts.s_name, ts.nation_name
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
), 
RevenueBySupplier AS (
    SELECT ts.s_suppkey, ts.s_name, SUM(od.l_extendedprice * (1 - od.l_discount)) AS total_revenue
    FROM OrderDetails od
    JOIN TopSuppliers ts ON od.s_suppkey = ts.s_suppkey
    GROUP BY ts.s_suppkey, ts.s_name
)
SELECT n.n_name AS nation_name, SUM(rb.total_revenue) AS total_revenue
FROM RevenueBySupplier rb
JOIN supplier s ON rb.s_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
GROUP BY n.n_name
ORDER BY total_revenue DESC;
