WITH SupplierPartDetails AS (
    SELECT 
        s.s_name AS supplier_name, 
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_name ORDER BY ps.ps_supplycost DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
FilteredSuppliers AS (
    SELECT 
        supplier_name, 
        part_name, 
        available_quantity, 
        supply_cost
    FROM 
        SupplierPartDetails
    WHERE 
        rank <= 3
)
SELECT 
    fs.supplier_name, 
    COUNT(*) AS top_parts_count, 
    SUM(fs.supply_cost) AS total_supply_cost, 
    AVG(fs.available_quantity) AS avg_available_quantity
FROM 
    FilteredSuppliers fs
GROUP BY 
    fs.supplier_name
ORDER BY 
    total_supply_cost DESC;
