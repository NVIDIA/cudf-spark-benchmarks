WITH SupplierOrders AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_quantity) AS total_quantity, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE s.s_acctbal > 0
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, so.total_quantity, so.order_count,
           RANK() OVER (ORDER BY so.total_quantity DESC) AS rank
    FROM SupplierOrders so
    JOIN supplier s ON so.s_suppkey = s.s_suppkey
)
SELECT ts.s_suppkey, ts.s_name, ts.total_quantity, ts.order_count
FROM TopSuppliers ts
WHERE ts.rank <= 10
ORDER BY ts.total_quantity DESC;
