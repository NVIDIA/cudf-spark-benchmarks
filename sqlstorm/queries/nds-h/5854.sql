WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.*, ROW_NUMBER() OVER (ORDER BY total_cost DESC) AS rank
    FROM RankedSuppliers s
    WHERE total_cost > 10000
),
RelevantOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, l.l_partkey, l.l_suppkey
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-12-31'
),
SupplierOrderSummary AS (
    SELECT rs.s_suppkey, COUNT(ro.o_orderkey) AS order_count, SUM(ro.o_totalprice) AS total_order_value
    FROM TopSuppliers rs
    JOIN RelevantOrders ro ON rs.s_suppkey = ro.l_suppkey
    GROUP BY rs.s_suppkey
)
SELECT ts.s_name, sos.order_count, sos.total_order_value
FROM SupplierOrderSummary sos
JOIN TopSuppliers ts ON sos.s_suppkey = ts.s_suppkey
ORDER BY sos.total_order_value DESC
LIMIT 10;