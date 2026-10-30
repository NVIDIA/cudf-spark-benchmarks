WITH SupplierPartDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, 
               ', Available: ', CAST(ps.ps_availqty AS STRING), 
               ', Cost: $', CAST(ps.ps_supplycost AS DECIMAL(12, 2))) AS details,
        ROW_NUMBER() OVER(PARTITION BY s.s_name ORDER BY ps.ps_supplycost DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    supplier_name,
    STRING_AGG(details, '; ') AS detailed_info
FROM 
    SupplierPartDetails
WHERE 
    rn <= 5
GROUP BY 
    supplier_name
ORDER BY 
    supplier_name;
