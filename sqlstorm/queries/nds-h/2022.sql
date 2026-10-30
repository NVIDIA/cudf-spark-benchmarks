WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT n.n_name AS region_name, sd.s_name AS supplier_name,
       COALESCE(co.total_spent, 0) AS total_spent_by_customer,
       sd.total_supply_cost
FROM SupplierDetails sd
FULL OUTER JOIN CustomerOrders co ON sd.s_nationkey = co.c_custkey
JOIN NationRegion n ON sd.s_nationkey = n.n_nationkey
WHERE (sd.total_supply_cost IS NOT NULL OR co.total_spent IS NOT NULL)
  AND (sd.s_acctbal > 1000 OR co.total_spent > 5000)
ORDER BY region_name, supplier_name;
