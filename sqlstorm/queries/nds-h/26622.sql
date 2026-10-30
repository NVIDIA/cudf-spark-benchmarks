WITH StringInfo AS (
    SELECT 
        p.p_name AS part_name,
        CONCAT('Brand: ', p.p_brand, ' | Type: ', p.p_type) AS branding_info,
        REPLACE(p.p_comment, 'special', 'unique') AS modified_comment,
        LENGTH(p.p_name) AS name_length
    FROM 
        part p
    WHERE 
        LENGTH(p.p_name) > 10
),
SupplierInfo AS (
    SELECT 
        s.s_name AS supplier_name,
        s.s_address AS supplier_address,
        s.s_comment AS supplier_comment,
        LENGTH(s.s_name) AS supplier_name_length
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
CombinedInfo AS (
    SELECT 
        si.part_name,
        si.branding_info,
        si.modified_comment,
        si.name_length,
        su.supplier_name,
        su.supplier_address,
        su.supplier_comment,
        su.supplier_name_length
    FROM 
        StringInfo si
    JOIN 
        SupplierInfo su ON si.name_length > su.supplier_name_length
)
SELECT 
    part_name,
    branding_info,
    modified_comment,
    supplier_name,
    supplier_address
FROM 
    CombinedInfo
ORDER BY 
    name_length DESC,
    supplier_name_length ASC
LIMIT 50;
