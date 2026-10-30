
WITH  nation_summary AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY AVG(s.s_acctbal) DESC) AS rn
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
    HAVING 
        AVG(s.s_acctbal) > (SELECT AVG(s_acctbal) FROM supplier)
),
part_supplier_summary AS (
    SELECT
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        MAX(ps.ps_supplycost) AS max_supply_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY
        p.p_partkey, p.p_name
)
SELECT 
    ps.p_name,
    ps.total_available,
    ps.total_supply_value,
    ROUND(ps.total_supply_value / NULLIF(ps.total_available, 0), 2) AS avg_supply_value,
    CASE 
        WHEN s.supplier_count IS NULL THEN 'No Suppliers'
        WHEN s.supplier_count > 5 THEN 'Many Suppliers'
        ELSE 'Few Suppliers'
    END AS supplier_category
FROM 
    part_supplier_summary ps
LEFT JOIN 
    nation_summary s ON ps.p_partkey IN (
        SELECT ps1.ps_partkey
        FROM partsupp ps1
        JOIN supplier s1 ON ps1.ps_suppkey = s1.s_suppkey
        JOIN nation n1 ON s1.s_nationkey = n1.n_nationkey
        WHERE n1.n_name IN (SELECT n_name FROM nation_summary WHERE rn = 1)
    )
WHERE 
    ps.total_available < 100
ORDER BY 
    avg_supply_value DESC
LIMIT 10;
