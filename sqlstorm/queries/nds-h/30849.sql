WITH  SupplyChain AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, s.s_name, s.s_nationkey, 
           ROW_NUMBER() OVER(PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_retailprice > 100.00

    UNION ALL

    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, s.s_name, s.s_nationkey,
           ROW_NUMBER() OVER(PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_retailprice <= 100.00 AND s.s_nationkey IN (
        SELECT n.n_nationkey 
        FROM nation n 
        WHERE n.n_name LIKE 'A%'
    )
)

SELECT n.n_name, 
       COUNT(DISTINCT sc.p_partkey) AS part_count, 
       SUM(sc.ps_supplycost) AS total_supply_cost,
       AVG(sc.ps_supplycost) AS avg_supply_cost
FROM SupplyChain sc
JOIN supplier s ON sc.s_name = s.s_name
JOIN nation n ON s.s_nationkey = n.n_nationkey
GROUP BY n.n_name
HAVING COUNT(DISTINCT sc.p_partkey) > 5
ORDER BY avg_supply_cost DESC;