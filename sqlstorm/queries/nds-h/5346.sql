WITH SupplyCost AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
NationRegion AS (
    SELECT n.n_nationkey, r.r_regionkey
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
SupplierParts AS (
    SELECT s.s_suppkey, COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
)
SELECT cr.c_custkey, cr.order_count, cr.total_spent, cs.total_supply_cost, sp.parts_supplied
FROM CustomerOrders cr
JOIN SupplyCost cs ON cr.c_custkey = (
    SELECT c.c_custkey
    FROM customer c
    WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n JOIN NationRegion nr ON n.n_nationkey = nr.n_nationkey)
    LIMIT 1
)
JOIN SupplierParts sp ON sp.s_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    ORDER BY ps.ps_supplycost DESC
    LIMIT 1
)
WHERE cr.total_spent > 10000
ORDER BY cr.total_spent DESC, cs.total_supply_cost ASC
LIMIT 50;
