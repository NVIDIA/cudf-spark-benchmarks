WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        p.p_retailprice,
        ps.ps_supplycost,
        ps.ps_availqty,
        s.s_comment,
        CONCAT(s.s_name, ' supplies ', p.p_name) AS supply_detail
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
RankedSuppliers AS (
    SELECT 
        supplier_name,
        part_name,
        p_retailprice,
        ps_supplycost,
        ps_availqty,
        s_comment,
        supply_detail,
        RANK() OVER (PARTITION BY part_name ORDER BY ps_supplycost ASC) AS cost_rank
    FROM 
        SupplierParts
)
SELECT 
    supplier_name,
    part_name,
    p_retailprice,
    ps_supplycost,
    ps_availqty,
    s_comment,
    supply_detail
FROM 
    RankedSuppliers
WHERE 
    cost_rank = 1
ORDER BY 
    supplier_name, part_name;
