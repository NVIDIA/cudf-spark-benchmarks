WITH PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        CONCAT('Part: ', p.p_name, ' | Supplier: ', s.s_name) AS part_supplier_details
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
RankedParts AS (
    SELECT 
        part_supplier_details,
        ps_supplycost,
        ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY ps_supplycost ORDER BY ps_availqty DESC) AS ranking
    FROM 
        PartSupplierInfo
)
SELECT 
    part_supplier_details,
    ps_supplycost,
    ps_availqty
FROM 
    RankedParts
WHERE 
    ranking <= 5
ORDER BY 
    ps_supplycost, ps_availqty DESC;
