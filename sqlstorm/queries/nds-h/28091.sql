WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' supplies ', p.p_name) AS supplier_part_info
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
RankedParts AS (
    SELECT 
        supplier_name,
        part_name,
        available_quantity,
        supply_cost,
        supplier_part_info,
        RANK() OVER (PARTITION BY supplier_name ORDER BY available_quantity DESC) AS rank
    FROM 
        SupplierParts
)
SELECT 
    supplier_name,
    part_name,
    available_quantity,
    supply_cost,
    supplier_part_info,
    CONCAT('Supplier ', supplier_name, ' offers ', part_name, ' with an available quantity of ', available_quantity, ' at a cost of ', supply_cost) AS detailed_info
FROM 
    RankedParts
WHERE 
    rank <= 5
ORDER BY 
    supplier_name, available_quantity DESC;
