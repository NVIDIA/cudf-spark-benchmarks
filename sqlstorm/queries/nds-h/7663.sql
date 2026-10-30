WITH SupplierDetails AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_nationkey, 
           s.s_acctbal, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
)
, NationalAverage AS (
    SELECT n.n_nationkey, 
           AVG(sd.total_supply_cost) AS avg_supply_cost
    FROM nation n
    JOIN SupplierDetails sd ON n.n_nationkey = sd.s_nationkey
    GROUP BY n.n_nationkey
)
SELECT r.r_name, 
       SUM(sd.total_supply_cost) AS total_cost, 
       na.avg_supply_cost
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN SupplierDetails sd ON n.n_nationkey = sd.s_nationkey
JOIN NationalAverage na ON n.n_nationkey = na.n_nationkey
WHERE sd.total_supply_cost > na.avg_supply_cost
GROUP BY r.r_name, na.avg_supply_cost
ORDER BY total_cost DESC
LIMIT 10;
