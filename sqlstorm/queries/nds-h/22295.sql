
WITH  SupplierCostCTE AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, total_supply_cost, RANK() OVER (ORDER BY total_supply_cost DESC) AS cost_rank
    FROM SupplierCostCTE s
),
CustomerRegion AS (
    SELECT c.c_custkey, n.n_name AS nation_name, r.r_name AS region_name
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, 
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
)
SELECT CR.region_name, SUM(OD.o_totalprice) AS total_order_value,
       COUNT(DISTINCT OD.o_orderkey) AS unique_orders,
       STRING_AGG(SS.s_name, ', ') AS suppliers_involved,
       CASE 
           WHEN SUM(OD.o_totalprice) > (SELECT AVG(total_supply_cost) FROM RankedSuppliers)
           THEN 'Above Average'
           ELSE 'Below Average'
       END AS cost_evaluation
FROM CustomerRegion CR
LEFT JOIN OrderDetails OD ON CR.c_custkey = OD.o_orderkey
LEFT JOIN RankedSuppliers SS ON OD.o_orderkey = SS.s_suppkey
WHERE CR.nation_name IS NOT NULL
  AND (OD.o_orderdate BETWEEN '1995-01-01' AND '1995-12-31' 
       OR OD.o_orderstatus = 'P') 
GROUP BY CR.region_name
HAVING COUNT(DISTINCT OD.o_orderkey) > 0
ORDER BY total_order_value DESC
LIMIT 10;
