WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           AVG(ps.ps_supplycost) AS avg_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
NationSupplier AS (
    SELECT n.n_name, sd.s_name, sd.avg_supplycost
    FROM nation n
    JOIN SupplierDetails sd ON n.n_nationkey = sd.s_nationkey
)
SELECT ns.n_name,
       COUNT(DISTINCT cs.c_custkey) AS total_customers,
       COALESCE(AVG(cs.total_revenue), 0) AS avg_revenue,
       MAX(ns.avg_supplycost) AS max_supply_cost
FROM NationSupplier ns
LEFT JOIN CustomerOrders cs ON ns.s_name = cs.c_name
WHERE ns.avg_supplycost > (SELECT AVG(avg_supplycost) 
                            FROM SupplierDetails)
GROUP BY ns.n_name
ORDER BY avg_revenue DESC, max_supply_cost DESC
LIMIT 10;
