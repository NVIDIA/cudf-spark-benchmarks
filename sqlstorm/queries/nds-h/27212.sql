WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        LENGTH(p.p_name) AS name_length,
        UPPER(p.p_comment) AS upper_comment,
        CONCAT('Brand: ', p.p_brand, ', Type: ', p.p_type) AS brand_type,
        REPLACE(p.p_comment, 'quality', 'quality-assured') AS modified_comment
    FROM 
        part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUBSTRING(s.s_address, 1, 20) AS short_address,
        CONCAT(SUBSTRING(s.s_phone, 1, 3), '-', SUBSTRING(s.s_phone, 4, 3), '-', SUBSTRING(s.s_phone, 7, 8)) AS formatted_phone
    FROM 
        supplier s
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        LENGTH(c.c_name) AS cust_name_length,
        CONCAT(c.c_address, ' - ', c.c_phone) AS address_phone_combined
    FROM 
        customer c
)
SELECT 
    pd.p_name,
    std.s_name,
    cd.c_name,
    cd.cust_name_length,
    pd.name_length,
    pd.upper_comment,
    pd.brand_type,
    pd.modified_comment,
    std.short_address,
    std.formatted_phone,
    cd.address_phone_combined
FROM 
    PartDetails pd
JOIN 
    SupplierDetails std ON pd.p_partkey = std.s_nationkey
JOIN 
    CustomerDetails cd ON std.s_nationkey = cd.c_custkey
WHERE 
    pd.name_length > 10 AND
    std.formatted_phone LIKE '123-%'
ORDER BY 
    pd.p_partkey, std.s_name, cd.c_name;
