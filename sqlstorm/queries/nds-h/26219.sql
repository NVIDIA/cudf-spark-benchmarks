WITH SupplierParts AS (
    SELECT 
        S.s_name AS supplier_name,
        P.p_name AS part_name,
        PS.ps_availqty AS available_quantity,
        PS.ps_supplycost AS supply_cost,
        CONCAT(S.s_name, ': ', P.p_name) AS supplier_part_info,
        LENGTH(CONCAT(S.s_name, ': ', P.p_name)) AS info_length
    FROM 
        supplier S
    JOIN 
        partsupp PS ON S.s_suppkey = PS.ps_suppkey
    JOIN 
        part P ON PS.ps_partkey = P.p_partkey
),
RankedSuppliers AS (
    SELECT 
        supplier_name,
        part_name,
        available_quantity,
        supply_cost,
        supplier_part_info,
        info_length,
        RANK() OVER (PARTITION BY part_name ORDER BY available_quantity DESC) AS rank
    FROM 
        SupplierParts
)
SELECT 
    supplier_name,
    part_name,
    available_quantity,
    supply_cost,
    supplier_part_info,
    info_length
FROM 
    RankedSuppliers
WHERE 
    rank = 1
ORDER BY 
    LENGTH(supplier_name) DESC, 
    available_quantity DESC;
