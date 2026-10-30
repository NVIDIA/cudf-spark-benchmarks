WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        p.p_container AS container_type,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' - ', p.p_name) AS supplier_part_details
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
RegionNation AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        CONCAT(r.r_name, ' | ', n.n_name) AS region_nation_details
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
)
SELECT 
    sp.supplier_part_details,
    rn.region_nation_details,
    SUM(sp.available_quantity) AS total_available_quantity,
    AVG(sp.supply_cost) AS avg_supply_cost
FROM 
    SupplierParts sp
JOIN 
    RegionNation rn ON TRUE
GROUP BY 
    sp.supplier_part_details, 
    rn.region_nation_details
ORDER BY 
    total_available_quantity DESC, 
    avg_supply_cost ASC
LIMIT 10;
