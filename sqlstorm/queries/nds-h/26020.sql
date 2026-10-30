
WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(s.s_comment, ' ', p.p_comment) AS combined_comment
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
RankedSuppliers AS (
    SELECT 
        supplier_name,
        part_name,
        ps_availqty,
        ps_supplycost,
        combined_comment,
        ROW_NUMBER() OVER (PARTITION BY part_name ORDER BY ps_supplycost DESC) AS rank
    FROM SupplierParts
)
SELECT 
    supplier_name,
    part_name,
    ps_availqty,
    CAST(ps_supplycost AS STRING) AS formatted_supplycost, -- Standard SQL type casting
    SUBSTRING(combined_comment, 1, 50) AS short_comment
FROM RankedSuppliers
WHERE rank <= 5
ORDER BY part_name, ps_supplycost DESC;
