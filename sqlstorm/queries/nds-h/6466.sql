WITH SupplierSummary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate <= DATE '1997-12-31'
    GROUP BY o.o_custkey
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, os.total_revenue
    FROM customer c
    JOIN OrderSummary os ON c.c_custkey = os.o_custkey
    WHERE os.total_revenue > 100000.00
),
TopSuppliers AS (
    SELECT ss.s_suppkey, ss.s_name, ss.total_cost
    FROM SupplierSummary ss
    ORDER BY ss.total_cost DESC
    LIMIT 5
)
SELECT hvc.c_name, hvc.total_revenue, ts.s_name, ts.total_cost
FROM HighValueCustomers hvc
JOIN TopSuppliers ts ON hvc.total_revenue > ts.total_cost
ORDER BY hvc.total_revenue DESC, ts.total_cost DESC;