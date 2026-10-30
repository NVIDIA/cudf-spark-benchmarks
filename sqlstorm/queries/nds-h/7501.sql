
WITH SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, ss.total_cost
    FROM SupplierStats ss
    JOIN supplier s ON ss.s_suppkey = s.s_suppkey
    ORDER BY ss.total_cost DESC
    LIMIT 10
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
HighValueOrders AS (
    SELECT od.o_orderkey, od.order_value, ts.s_name
    FROM OrderDetails od
    JOIN lineitem l ON od.o_orderkey = l.l_orderkey
    JOIN TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
)
SELECT hvo.o_orderkey, hvo.order_value, hvo.s_name
FROM HighValueOrders hvo
ORDER BY hvo.order_value DESC;
