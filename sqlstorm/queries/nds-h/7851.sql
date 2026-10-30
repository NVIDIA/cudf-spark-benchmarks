
WITH SupplierCosts AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, sc.total_supply_cost
    FROM supplier s
    JOIN SupplierCosts sc ON s.s_suppkey = sc.s_suppkey
    ORDER BY sc.total_supply_cost DESC
    LIMIT 10
),
HighValueOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
SupplierOrderCount AS (
    SELECT ts.s_suppkey, COUNT(DISTINCT ho.o_orderkey) AS order_count
    FROM TopSuppliers ts
    JOIN lineitem l ON ts.s_suppkey = l.l_suppkey
    JOIN HighValueOrders ho ON l.l_orderkey = ho.o_orderkey
    GROUP BY ts.s_suppkey
)
SELECT ts.s_suppkey, ts.s_name, COALESCE(soc.order_count, 0) AS order_count, sc.total_supply_cost
FROM TopSuppliers ts
LEFT JOIN SupplierOrderCount soc ON ts.s_suppkey = soc.s_suppkey
JOIN SupplierCosts sc ON ts.s_suppkey = sc.s_suppkey
ORDER BY COALESCE(soc.order_count, 0) DESC, ts.s_name;
