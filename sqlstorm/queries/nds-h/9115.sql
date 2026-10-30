WITH SupplierCost AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_name, sc.total_cost
    FROM SupplierCost sc
    JOIN supplier s ON sc.s_suppkey = s.s_suppkey
    ORDER BY sc.total_cost DESC
    LIMIT 10
),
CustomerOrders AS (
    SELECT c.c_name, SUM(o.o_totalprice) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_name
),
TopCustomers AS (
    SELECT c.c_name, co.total_orders
    FROM CustomerOrders co
    JOIN customer c ON co.c_name = c.c_name
    ORDER BY co.total_orders DESC
    LIMIT 10
)
SELECT 
    ts.s_name AS Top_Supplier, 
    ts.total_cost AS Supplier_Cost, 
    tc.c_name AS Top_Customer, 
    tc.total_orders AS Customer_Orders
FROM TopSuppliers ts
CROSS JOIN TopCustomers tc
WHERE ts.total_cost > 100000
ORDER BY ts.total_cost DESC, tc.total_orders DESC;
