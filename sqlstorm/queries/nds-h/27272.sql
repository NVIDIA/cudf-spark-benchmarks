WITH PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        s.s_phone,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
EnhancedInfo AS (
    SELECT 
        psi.p_partkey,
        psi.p_name,
        psi.supplier_name,
        psi.s_phone,
        psi.ps_availqty,
        psi.ps_supplycost,
        psi.ps_comment,
        CONCAT('Supplier: ', psi.supplier_name, ', Phone: ', TRIM(psi.s_phone), ', Availability: ', psi.ps_availqty) AS supplier_info,
        CONCAT(psi.ps_comment, ' [Cost: ', psi.ps_supplycost, ']') AS detailed_comment
    FROM 
        PartSupplierInfo psi
    WHERE 
        psi.rn = 1
)
SELECT 
    e.p_partkey,
    e.p_name,
    e.supplier_info,
    e.detailed_comment
FROM 
    EnhancedInfo e
ORDER BY 
    e.p_partkey;
