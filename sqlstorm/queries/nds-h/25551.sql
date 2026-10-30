
WITH StringAggregation AS (
    SELECT 
        p.p_partkey,
        CONCAT('Part: ', p.p_name, ' | Brand: ', p.p_brand, ' | Type: ', p.p_type, 
               ' | Comment: ', p.p_comment) AS full_description,
        LENGTH(CONCAT('Part: ', p.p_name, ' | Brand: ', p.p_brand, ' | Type: ', p.p_type, 
                      ' | Comment: ', p.p_comment)) AS description_length
    FROM 
        part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        CONCAT(s.s_name, ' from ', s.s_address, 
               ' | Phone: ', s.s_phone, 
               ' | NationKey: ', s.s_nationkey) AS supplier_information
    FROM 
        supplier s
),
Combined AS (
    SELECT 
        sa.full_description,
        sd.supplier_information,
        sa.description_length
    FROM 
        StringAggregation sa
    JOIN 
        partsupp ps ON ps.ps_partkey = sa.p_partkey
    JOIN 
        SupplierDetails sd ON sd.s_suppkey = ps.ps_suppkey
)
SELECT 
    full_description,
    supplier_information,
    description_length
FROM 
    Combined
ORDER BY 
    description_length DESC
LIMIT 10;
