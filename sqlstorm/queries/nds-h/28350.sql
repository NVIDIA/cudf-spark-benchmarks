
WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name, 
        p.p_name AS part_name, 
        ps.ps_availqty AS available_quantity, 
        ps.ps_supplycost AS supply_cost, 
        s.s_name || ' supplies ' || p.p_name AS supply_info
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
RegionNations AS (
    SELECT 
        r.r_name AS region_name, 
        n.n_name AS nation_name, 
        n.n_name || ' is in region ' || r.r_name AS nation_info
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    sp.supplier_name,
    sp.part_name,
    sp.available_quantity,
    sp.supply_cost,
    rp.region_name,
    rp.nation_name,
    LENGTH(sp.supply_info) AS supply_info_length,
    LENGTH(rp.nation_info) AS nation_info_length
FROM 
    SupplierParts sp
JOIN 
    RegionNations rp ON sp.supplier_name LIKE '%' || rp.nation_name || '%'
WHERE 
    sp.available_quantity > 0 
ORDER BY 
    sp.available_quantity DESC, 
    sp.supply_cost ASC;
