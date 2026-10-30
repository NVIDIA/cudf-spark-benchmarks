WITH SupplierCost AS (
    SELECT ps_partkey, ps_suppkey, SUM(ps_supplycost) AS total_supply_cost
    FROM partsupp
    GROUP BY ps_partkey, ps_suppkey
),
Ranking AS (
    SELECT s.s_suppkey, s.s_name,
           SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity,
           RANK() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_within_region
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE l.l_shipdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
    GROUP BY s.s_suppkey, s.s_name, r.r_regionkey
)
SELECT r.s_suppkey, r.s_name, r.rank_within_region,
       COALESCE(fc.total_supply_cost, 0) AS first_class_supply_cost,
       CASE WHEN r.total_returned_quantity > 100 THEN 'High Return' ELSE 'Normal Return' END AS return_category
FROM Ranking r
LEFT JOIN SupplierCost fc ON r.s_suppkey = fc.ps_suppkey
WHERE r.rank_within_region <= 5
ORDER BY r.rank_within_region, r.s_suppkey;
