WITH  PartSuppliers AS (
    SELECT ps_partkey, ps_suppkey, ps_availqty, ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost ASC) as rn
    FROM partsupp
    WHERE ps_availqty > 0
),
HighDemand AS (
    SELECT l_partkey, SUM(l_quantity) AS total_demand
    FROM lineitem
    WHERE l_returnflag = 'N'
    GROUP BY l_partkey
    HAVING SUM(l_quantity) > (
        SELECT AVG(total_quantity)
        FROM (
            SELECT SUM(l_quantity) as total_quantity
            FROM lineitem
            WHERE l_shipdate >= '1996-01-01'
            GROUP BY l_orderkey
        ) AS average_orders
    )
),
SubQueryMaxCost AS (
    SELECT ps_suppkey, MAX(ps_supplycost) AS max_cost
    FROM partsupp
    GROUP BY ps_suppkey
),
RelevantSuppliers AS (
    SELECT s.s_name, s.s_nationkey, p.p_partkey, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN PartSuppliers ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON p.p_partkey = ps.ps_partkey
    WHERE s.s_acctbal > 1000 AND EXISTS (
        SELECT 1
        FROM HighDemand hd
        WHERE hd.l_partkey = p.p_partkey
    )
),
FinalSelection AS (
    SELECT rs.s_name, rs.s_nationkey, rs.ps_availqty, rs.ps_supplycost,
           CASE 
               WHEN rs.ps_supplycost > (SELECT MAX(max_cost) FROM SubQueryMaxCost) THEN 'High Cost'
               ELSE 'Standard Cost'
           END AS cost_category
    FROM RelevantSuppliers rs
),
FinalResults AS (
    SELECT f.s_name, f.s_nationkey, COUNT(f.ps_availqty) as num_parts,
           SUM(f.ps_supplycost) as total_supply_cost
    FROM FinalSelection f
    GROUP BY f.s_name, f.s_nationkey
)
SELECT DISTINCT fr.s_name, fr.s_nationkey, fr.num_parts, fr.total_supply_cost
FROM FinalResults fr
LEFT JOIN nation n ON n.n_nationkey = fr.s_nationkey
WHERE fr.num_parts IS NOT NULL
  AND (n.n_comment IS NULL OR n.n_comment NOT LIKE '%test%')
ORDER BY fr.total_supply_cost DESC NULLS LAST
LIMIT 10 OFFSET 0;