WITH SupplierCost AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrder AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT s.s_name, sc.total_cost
    FROM SupplierCost sc
    JOIN supplier s ON sc.s_suppkey = s.s_suppkey
    ORDER BY sc.total_cost DESC
    LIMIT 10
),
TopCustomers AS (
    SELECT c.c_name, co.total_spent
    FROM CustomerOrder co
    JOIN customer c ON co.c_custkey = c.c_custkey
    ORDER BY co.total_spent DESC
    LIMIT 10
)
SELECT ts.s_name AS Supplier, tc.c_name AS Customer, tc.total_spent AS Customer_Spending, ts.total_cost AS Supplier_Cost
FROM TopSuppliers ts
CROSS JOIN TopCustomers tc
ORDER BY ts.total_cost DESC, tc.total_spent DESC;
