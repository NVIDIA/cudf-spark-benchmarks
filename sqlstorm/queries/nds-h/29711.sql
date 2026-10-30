WITH PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(p.p_name, ' | ', s.s_name, ' | ', ps.ps_availqty) AS combined_info
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
FormattedSupplierInfo AS (
    SELECT 
        p_partkey,
        p_name,
        supplier_name,
        ps_availqty,
        ps_supplycost,
        UPPER(combined_info) AS upper_combined_info,
        LENGTH(combined_info) AS combined_length
    FROM 
        PartSupplierInfo
),
FilteredInfo AS (
    SELECT 
        p_partkey,
        p_name,
        supplier_name,
        ps_availqty,
        ps_supplycost,
        upper_combined_info,
        combined_length
    FROM 
        FormattedSupplierInfo
    WHERE 
        ps_availqty > 50 
        AND ps_supplycost < 1000
)
SELECT 
    f.p_partkey,
    f.p_name,
    f.supplier_name,
    f.ps_availqty,
    f.ps_supplycost,
    f.upper_combined_info,
    f.combined_length
FROM 
    FilteredInfo f
ORDER BY 
    f.combined_length DESC, f.p_name ASC;
