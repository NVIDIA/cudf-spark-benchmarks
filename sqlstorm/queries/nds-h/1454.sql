WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS num_suppliers,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    ss.s_name AS supplier_name,
    ss.total_supply_cost,
    ss.num_parts,
    ns.num_suppliers,
    ns.total_acctbal,
    CASE 
        WHEN ss.total_supply_cost IS NULL THEN 'No Cost' 
        ELSE 'Has Cost' 
    END AS cost_status
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierStats ss ON n.n_nationkey = ss.s_suppkey
LEFT JOIN 
    NationSummary ns ON n.n_nationkey = ns.n_nationkey
WHERE 
    (ss.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierStats) OR ss.total_supply_cost IS NULL)
    AND n.n_name IS NOT NULL
ORDER BY 
    region_name, nation_name, total_supply_cost DESC
LIMIT 100;
