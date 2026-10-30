
WITH SupplierAggregates AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
OrderSummary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.nation_name, s.total_cost,
           RANK() OVER (ORDER BY s.total_cost DESC) AS rank
    FROM SupplierAggregates s
),
TopCustomers AS (
    SELECT o.c_custkey, o.c_name, o.order_count, o.total_spent,
           RANK() OVER (ORDER BY o.total_spent DESC) AS rank
    FROM OrderSummary o
)
SELECT ts.s_name AS supplier_name, tc.c_name AS customer_name, ts.total_cost, tc.total_spent
FROM TopSuppliers ts
JOIN TopCustomers tc ON ts.rank = tc.rank
WHERE ts.rank <= 10
ORDER BY ts.total_cost DESC, tc.total_spent DESC;
