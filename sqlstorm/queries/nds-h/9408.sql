
WITH CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, c.total_orders, c.total_spent,
           RANK() OVER (ORDER BY c.total_spent DESC) AS rank
    FROM CustomerOrders c
    WHERE c.total_orders > 0
),
PartSupplierInfo AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS part_supply_value
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.part_supply_value) AS total_supply_value
    FROM PartSupplierInfo ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT t.c_custkey, t.c_name, t.total_orders, t.total_spent, 
       s.s_suppkey, s.s_name, s.total_supply_value
FROM TopCustomers t
JOIN SupplierDetails s ON s.total_supply_value > (SELECT AVG(total_supply_value) FROM SupplierDetails)
WHERE t.rank <= 10
ORDER BY t.total_spent DESC, s.total_supply_value DESC;
