WITH CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
),
SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, total_spent
    FROM CustomerOrders c
    WHERE total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, total_supply_value
    FROM SupplierParts s
    WHERE total_supply_value > (SELECT AVG(total_supply_value) FROM SupplierParts)
)
SELECT c.c_name AS customer_name, s.s_name AS supplier_name, c.total_spent, s.total_supply_value
FROM HighValueCustomers c
JOIN TopSuppliers s ON c.c_custkey % 10 = s.s_suppkey % 10
ORDER BY c.total_spent DESC, s.total_supply_value DESC
LIMIT 50;