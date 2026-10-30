WITH SupplierParts AS (
    SELECT s.s_name, p.p_name, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
TopSuppliers AS (
    SELECT s_name, p_name, ps_availqty, ps_supplycost
    FROM SupplierParts
    WHERE rank <= 3
),
AggregatedData AS (
    SELECT p_name, COUNT(s_name) AS supplier_count,
           SUM(ps_supplycost) AS total_supply_cost,
           AVG(ps_supplycost) AS avg_supply_cost
    FROM TopSuppliers
    GROUP BY p_name
),
FinalResults AS (
    SELECT p.p_name, a.supplier_count, a.total_supply_cost, a.avg_supply_cost,
           CASE 
               WHEN a.avg_supply_cost > 100 THEN 'High Cost'
               WHEN a.avg_supply_cost BETWEEN 50 AND 100 THEN 'Moderate Cost'
               ELSE 'Low Cost'
           END AS cost_category
    FROM part p
    LEFT JOIN AggregatedData a ON p.p_name = a.p_name
)
SELECT fr.p_name, COALESCE(fr.supplier_count, 0) AS supplier_count,
       COALESCE(fr.total_supply_cost, 0.00) AS total_supply_cost,
       COALESCE(fr.avg_supply_cost, 0.00) AS avg_supply_cost,
       fr.cost_category
FROM FinalResults fr
ORDER BY fr.p_name;
