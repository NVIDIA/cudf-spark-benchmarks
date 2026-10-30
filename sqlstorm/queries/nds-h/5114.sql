WITH TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_cost DESC
    LIMIT 10
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    c.c_name AS Customer_Name,
    c.order_count AS Total_Orders,
    c.total_spent AS Total_Spent,
    s.s_name AS Supplier_Name,
    s.total_supply_cost AS Supplier_Cost
FROM CustomerOrders c
CROSS JOIN TopSuppliers s
WHERE c.total_spent > (
    SELECT AVG(total_spent) FROM CustomerOrders
) AND s.total_supply_cost < (
    SELECT MAX(total_supply_cost) FROM TopSuppliers
)
ORDER BY c.total_spent DESC, s.total_supply_cost ASC;
