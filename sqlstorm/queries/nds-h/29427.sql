WITH PartSupplier AS (
    SELECT 
        p.p_name,
        s.s_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        ROW_NUMBER() OVER(PARTITION BY p.p_name ORDER BY ps.ps_supplycost ASC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
TopSuppliers AS (
    SELECT 
        p_name,
        s_name,
        ps_supplycost,
        ps_availqty
    FROM 
        PartSupplier
    WHERE 
        rn <= 3
),
Info AS (
    SELECT 
        ts.p_name,
        ts.s_name,
        ts.ps_supplycost,
        ts.ps_availqty,
        CONCAT('Supplier: ', ts.s_name, ' | Part: ', ts.p_name, ' | Cost: ', CAST(ts.ps_supplycost AS STRING), ' | Available: ', CAST(ts.ps_availqty AS STRING)) AS supplier_info
    FROM 
        TopSuppliers ts
)
SELECT 
    TRIM(CONCAT(supplier_info, ' | ', REPLACE(supplier_info, 'Supplier:', 'Supplier Details:'))) AS formatted_info
FROM 
    Info
ORDER BY 
    ps_supplycost DESC;
