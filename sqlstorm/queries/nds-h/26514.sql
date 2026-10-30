WITH RegionalSupplierData AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        s.s_name AS supplier_name,
        COUNT(DISTINCT p.p_partkey) AS total_parts,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        r.r_name, n.n_name, s.s_name
),
ProcessedData AS (
    SELECT 
        region_name,
        nation_name,
        supplier_name,
        total_parts,
        total_available_quantity,
        total_supply_cost,
        CONCAT(supplier_name, ' in ', nation_name, ', ', region_name) AS supplier_full_location,
        CASE 
            WHEN total_available_quantity > 500 THEN 'High Supply'
            WHEN total_available_quantity BETWEEN 200 AND 500 THEN 'Medium Supply'
            ELSE 'Low Supply'
        END AS supply_level
    FROM 
        RegionalSupplierData
)
SELECT 
    region_name,
    nation_name,
    supplier_name,
    supplier_full_location,
    total_parts,
    total_available_quantity,
    total_supply_cost,
    supply_level
FROM 
    ProcessedData
WHERE 
    total_supply_cost > 1000
ORDER BY 
    region_name, nation_name, supplier_name;
