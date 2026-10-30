WITH SupplierPartInfo AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        p.p_brand AS part_brand,
        ps.ps_supplycost AS supply_cost,
        ps.ps_availqty AS available_quantity,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), FilteredSuppliers AS (
    SELECT 
        supplier_name,
        part_name,
        part_brand,
        supply_cost,
        available_quantity
    FROM 
        SupplierPartInfo
    WHERE 
        rn = 1
)
SELECT 
    p.p_type,
    COUNT(DISTINCT f.supplier_name) AS unique_suppliers,
    SUM(f.available_quantity) AS total_available_quantity,
    AVG(f.supply_cost) AS average_supply_cost,
    MAX(f.supply_cost) AS max_supply_cost,
    MIN(f.supply_cost) AS min_supply_cost
FROM 
    part p
JOIN 
    FilteredSuppliers f ON p.p_name = f.part_name
GROUP BY 
    p.p_type
ORDER BY 
    unique_suppliers DESC, total_available_quantity DESC;
