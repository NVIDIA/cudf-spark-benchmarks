WITH CustomerOrders AS (
    SELECT c.c_custkey, 
           c.c_name, 
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    INNER JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           RANK() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS cost_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueCustomers AS (
    SELECT c.c_custkey, 
           c.c_name, 
           co.total_spent
    FROM customer c
    JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
)
SELECT hvc.c_custkey,
       hvc.c_name,
       hvc.total_spent,
       sp.s_name AS supplier_name,
       sp.total_available,
       sp.avg_supply_cost
FROM HighValueCustomers hvc
LEFT JOIN SupplierParts sp ON hvc.total_spent > sp.avg_supply_cost
WHERE sp.total_available IS NOT NULL
ORDER BY hvc.total_spent DESC, sp.total_available DESC
LIMIT 10;

