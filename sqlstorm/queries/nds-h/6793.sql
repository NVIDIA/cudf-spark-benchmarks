WITH CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
LineItemSummary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    WHERE l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-12-31'
    GROUP BY l.l_orderkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, co.total_spent
    FROM CustomerOrders co
    JOIN customer c ON co.c_custkey = c.c_custkey
    ORDER BY co.total_spent DESC
    LIMIT 10
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, sp.total_cost
    FROM SupplierParts sp
    JOIN supplier s ON sp.s_suppkey = s.s_suppkey
    ORDER BY sp.total_cost DESC
    LIMIT 10
)
SELECT tc.c_name AS Top_Customers_Name, tp.s_name AS Top_Suppliers_Name, 
       tc.total_spent AS Customer_Spent, tp.total_cost AS Supplier_Cost
FROM TopCustomers tc
CROSS JOIN TopSuppliers tp
ORDER BY tc.total_spent DESC, tp.total_cost DESC;