
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, rs.total_supply_cost
    FROM RankedSuppliers rs
    JOIN supplier s ON rs.s_suppkey = s.s_suppkey
    ORDER BY rs.total_supply_cost DESC
    LIMIT 5
),
OrdersWithCustomer AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_name, c.c_acctbal
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.c_name, o.c_acctbal
    FROM OrdersWithCustomer o
    WHERE o.o_totalprice > (SELECT AVG(o_totalprice) FROM OrdersWithCustomer)
)
SELECT hvo.o_orderkey, hvo.o_totalprice, hvo.c_name, hvo.c_acctbal, ts.s_name
FROM HighValueOrders hvo
JOIN lineitem li ON hvo.o_orderkey = li.l_orderkey
JOIN TopSuppliers ts ON li.l_suppkey = ts.s_suppkey
ORDER BY hvo.o_totalprice DESC, ts.total_supply_cost DESC;
