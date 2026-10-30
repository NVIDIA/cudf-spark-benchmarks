WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        n.n_name AS nation_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank_within_region
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
HighValueParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_supplycost) > 100.00
)
SELECT 
    r.r_name, 
    rs.s_name, 
    rs.s_address, 
    hvp.p_name, 
    hvp.supplier_count, 
    hvp.total_supply_cost
FROM 
    RankedSuppliers rs
JOIN 
    nation n ON rs.nation_name = n.n_name
JOIN 
    HighValueParts hvp ON hvp.supplier_count > 5
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    rs.rank_within_region <= 3
ORDER BY 
    r.r_name, rs.s_acctbal DESC, hvp.total_supply_cost DESC;
