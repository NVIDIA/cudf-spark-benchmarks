
WITH RegionalSuppliers AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_name, r.r_name
),
PartSupplies AS (
    SELECT 
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_comment,
        r.r_name AS region_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ps.ps_availqty > 0
)
SELECT 
    rs.nation_name,
    rs.region_name,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    SUM(ps.ps_availqty) AS total_available_quantity,
    COUNT(DISTINCT ps.p_name) AS part_count
FROM 
    RegionalSuppliers rs
LEFT JOIN 
    PartSupplies ps ON rs.region_name = ps.region_name
GROUP BY 
    rs.nation_name, rs.region_name
ORDER BY 
    rs.region_name, avg_supply_cost DESC
LIMIT 10;
