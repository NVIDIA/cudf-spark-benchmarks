WITH StringBench AS (
    SELECT 
        p_name,
        p_mfgr,
        p_brand,
        p_type,
        p_comment,
        CONCAT(p_name, ' (', p_mfgr, ')') AS full_description,
        LENGTH(p_name) AS name_length,
        LENGTH(p_comment) AS comment_length,
        REPLACE(p_comment, 'good', 'excellent') AS modified_comment,
        UPPER(p_brand) AS upper_brand,
        LOWER(p_type) AS lower_type
    FROM 
        part
), RegionSupplier AS (
    SELECT 
        r.r_name AS region_name,
        s.s_name AS supplier_name,
        CONCAT(s.s_name, ' from ', r.r_name) AS supplier_location,
        LENGTH(s.s_name) AS supplier_name_length
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    sb.full_description,
    sb.name_length,
    sb.comment_length,
    sb.modified_comment,
    rs.supplier_location,
    rs.supplier_name_length
FROM 
    StringBench sb
JOIN 
    RegionSupplier rs ON sb.p_brand = rs.supplier_name
WHERE 
    sb.name_length > 30 AND 
    rs.supplier_name_length > 15
ORDER BY 
    sb.name_length DESC, 
    rs.supplier_name_length ASC
LIMIT 10;
