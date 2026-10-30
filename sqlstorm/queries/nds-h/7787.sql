WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT C.c_custkey, C.c_name, C.total_spent, 
           ROW_NUMBER() OVER (ORDER BY C.total_spent DESC) AS rank
    FROM CustomerOrders C
    WHERE C.total_spent > 5000
),
FinalReport AS (
    SELECT HV.c_custkey, HV.c_name, HV.total_spent, 
           RS.s_name AS top_supplier,
           RS.total_supply_value
    FROM HighValueCustomers HV
    JOIN RankedSuppliers RS ON HV.c_custkey % 10 = RS.rn  
)
SELECT * 
FROM FinalReport
ORDER BY total_spent DESC, total_supply_value DESC
LIMIT 100;