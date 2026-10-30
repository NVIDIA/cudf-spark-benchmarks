WITH SupplierPartDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        p.p_mfgr AS manufacturer,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT('Supplier ', s.s_name, ' provides part ', p.p_name, ' manufactured by ', p.p_mfgr, ' with an available quantity of ', ps.ps_availqty, ' at a cost of ', ps.ps_supplycost) AS details
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
FilteredDetails AS (
    SELECT 
        *,
        LENGTH(details) AS detail_length,
        UPPER(substring(details, 1, 30)) AS brief_description
    FROM 
        SupplierPartDetails
),
FinalBenchmark AS (
    SELECT 
        supplier_name,
        part_name,
        manufacturer,
        available_quantity,
        supply_cost,
        detail_length,
        brief_description
    FROM 
        FilteredDetails
    WHERE 
        available_quantity > 50
    ORDER BY 
        detail_length DESC
)
SELECT 
    supplier_name, 
    part_name, 
    manufacturer, 
    available_quantity, 
    supply_cost, 
    detail_length, 
    brief_description 
FROM 
    FinalBenchmark
LIMIT 100;
