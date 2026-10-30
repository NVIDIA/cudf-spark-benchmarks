
WITH  supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_nationkey
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'Eu%')
      AND s.s_acctbal < (SELECT AVG(s_acctbal) FROM supplier)
)

SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_avail_qty,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    MAX(s.s_acctbal) AS max_acctbal_supplier,
    CASE 
        WHEN AVG(ps.ps_supplycost) < 1000 THEN 'Low Cost'
        WHEN AVG(ps.ps_supplycost) BETWEEN 1000 AND 5000 THEN 'Medium Cost'
        ELSE 'High Cost'
    END AS cost_category
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    AND p.p_size IS NOT NULL
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 0
ORDER BY 
    total_avail_qty DESC
LIMIT 10;
