WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers
    FROM 
        partsupp ps
    JOIN 
        RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
    WHERE 
        rs.rank <= 5  
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    hv.total_supply_cost,
    hv.num_suppliers,
    CASE 
        WHEN hv.total_supply_cost IS NULL THEN 'No Supply'
        WHEN hv.num_suppliers >= 5 THEN 'Highly Supplied'
        ELSE 'Moderately Supplied'
    END AS supply_status
FROM 
    part p
LEFT JOIN 
    HighValueParts hv ON p.p_partkey = hv.ps_partkey
WHERE 
    p.p_retailprice > 1000
ORDER BY 
    hv.total_supply_cost DESC NULLS LAST, 
    p.p_name ASC
LIMIT 20;