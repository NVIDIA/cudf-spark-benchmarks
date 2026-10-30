WITH RegionalSuppliers AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_name AS supplier_name,
        COUNT(ps.ps_partkey) AS total_parts_supply,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_name, r.r_name, s.s_name
),
HighValueNations AS (
    SELECT 
        nation_name,
        region_name,
        supplier_name,
        total_parts_supply,
        total_supply_cost
    FROM 
        RegionalSuppliers
    WHERE 
        total_supply_cost > (SELECT AVG(total_supply_cost) FROM RegionalSuppliers)
)
SELECT 
    nation_name,
    region_name,
    supplier_name,
    total_parts_supply,
    ROUND(total_supply_cost, 2) AS rounded_supply_cost
FROM 
    HighValueNations
ORDER BY 
    total_parts_supply DESC, 
    nation_name ASC;
