
WITH SupplierTotal AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, st.total_cost
    FROM SupplierTotal st
    JOIN supplier s ON st.s_suppkey = s.s_suppkey
    ORDER BY st.total_cost DESC
    LIMIT 10
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS orders_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > (SELECT AVG(total_spent) FROM (
        SELECT SUM(o.o_totalprice) AS total_spent
        FROM orders o
        GROUP BY o.o_custkey
    ) AS avg_spent)
)
SELECT ts.s_name AS Supplier_Name, COALESCE(co.orders_count, 0) AS Orders_Count,
       COALESCE(co.total_spent, 0) AS Total_Spent, ts.total_cost AS Supplier_Total_Cost
FROM TopSuppliers ts
LEFT JOIN CustomerOrders co ON ts.s_suppkey = co.c_custkey
ORDER BY ts.total_cost DESC, COALESCE(co.total_spent, 0) DESC;
