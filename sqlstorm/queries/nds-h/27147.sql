WITH SupplierPartDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' with a quantity of ', ps.ps_availqty, ' at a cost of $', ps.ps_supplycost) AS summary
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
FilteredSupplierParts AS (
    SELECT 
        supplier_name,
        part_name,
        available_quantity,
        supply_cost,
        summary
    FROM 
        SupplierPartDetails
    WHERE 
        available_quantity > 100 AND 
        supply_cost BETWEEN 10.00 AND 50.00
),
AggregatedResults AS (
    SELECT 
        supplier_name,
        COUNT(part_name) AS number_of_parts,
        SUM(supply_cost) AS total_supply_cost
    FROM 
        FilteredSupplierParts
    GROUP BY 
        supplier_name
)
SELECT 
    supplier_name,
    number_of_parts,
    total_supply_cost,
    CONCAT(supplier_name, ' supplies a total of ', number_of_parts, ' parts with a total supply cost of $', total_supply_cost) AS detailed_report
FROM 
    AggregatedResults
ORDER BY 
    total_supply_cost DESC;
