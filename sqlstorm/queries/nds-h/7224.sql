WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
HighestCostSuppliers AS (
    SELECT rnk.s_nationkey, rnk.s_suppkey, rnk.s_name, rnk.total_cost, 
           ROW_NUMBER() OVER (PARTITION BY rnk.s_nationkey ORDER BY rnk.total_cost DESC) AS rnk
    FROM RankedSuppliers rnk
)
SELECT n.n_name, rc.s_name, rc.total_cost
FROM HighestCostSuppliers rc
JOIN nation n ON rc.s_nationkey = n.n_nationkey
WHERE rc.rnk <= 3
ORDER BY n.n_name, rc.total_cost DESC;
