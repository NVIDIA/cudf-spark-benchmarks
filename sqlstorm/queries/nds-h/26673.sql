WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_availqty DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
TopSuppliers AS (
    SELECT 
        supplier_name,
        part_name,
        available_quantity,
        supply_cost
    FROM 
        SupplierParts
    WHERE 
        rank <= 5
)
SELECT 
    ts.supplier_name,
    COUNT(DISTINCT ts.part_name) AS total_parts,
    SUM(ts.available_quantity) AS total_available_quantity,
    AVG(ts.supply_cost) AS average_supply_cost
FROM 
    TopSuppliers ts
GROUP BY 
    ts.supplier_name
HAVING 
    COUNT(DISTINCT ts.part_name) > 1
ORDER BY 
    total_available_quantity DESC;
