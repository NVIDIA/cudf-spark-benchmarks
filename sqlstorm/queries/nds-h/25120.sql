WITH SupplierPartDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' with a cost of $', CAST(ps.ps_supplycost AS STRING), ' and availability of ', CAST(ps.ps_availqty AS STRING), ' units.') AS supply_info
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
RegionNationDetails AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        CONCAT(n.n_name, ' belongs to the region ', r.r_name, '.') AS nation_region_info
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    spd.supplier_name,
    spd.part_name,
    spd.available_quantity,
    spd.supply_cost,
    spd.supply_info,
    rnd.region_name,
    rnd.nation_name,
    rnd.nation_region_info
FROM 
    SupplierPartDetails spd
JOIN 
    RegionNationDetails rnd ON spd.supplier_name LIKE CONCAT('%', rnd.nation_name, '%')
ORDER BY 
    spd.supply_cost DESC, 
    spd.available_quantity ASC;
