
WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        (ps.ps_availqty * ps.ps_supplycost) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
AggregatedValues AS (
    SELECT 
        supplier_name,
        COUNT(part_name) AS total_parts,
        SUM(available_quantity) AS total_available_quantity,
        SUM(total_supply_value) AS total_value
    FROM 
        SupplierParts
    GROUP BY 
        supplier_name
),
RankedSuppliers AS (
    SELECT 
        supplier_name,
        total_parts,
        total_available_quantity,
        total_value,
        RANK() OVER (ORDER BY total_value DESC) AS value_rank
    FROM 
        AggregatedValues
)
SELECT 
    supplier_name,
    total_parts,
    total_available_quantity,
    total_value,
    LPAD(CAST(value_rank AS STRING), 3, '0') AS rank_formatted,
    CONCAT('Supplier: ', supplier_name, ', Total Parts: ', total_parts, ', Total Available Quantity: ', total_available_quantity, ', Total Value: ', total_value) AS details
FROM 
    RankedSuppliers
WHERE 
    value_rank <= 10
ORDER BY 
    value_rank;
