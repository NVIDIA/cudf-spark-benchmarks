WITH StringBenchmark AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        UPPER(p.p_brand) AS upper_brand,
        LOWER(CONCAT(p.p_name, ' - ', p.p_type)) AS lower_concatenated,
        REPLACE(p.p_comment, ' ', '_') AS comment_underscore,
        CASE 
            WHEN LENGTH(p.p_name) > 30 THEN 'LONG NAME' 
            ELSE 'SHORT NAME' 
        END AS name_classification
    FROM 
        part p
),
SupplierData AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        CONCAT(s.s_name, ' | ', s.s_address) AS supplier_info,
        SUBSTRING(s.s_comment FROM 1 FOR 50) AS short_comment
    FROM 
        supplier s
)
SELECT 
    sb.p_partkey,
    sb.name_length,
    sb.upper_brand,
    sb.lower_concatenated,
    sb.comment_underscore,
    sb.name_classification,
    sd.s_suppkey,
    sd.supplier_info,
    sd.short_comment
FROM 
    StringBenchmark sb
JOIN 
    partsupp ps ON sb.p_partkey = ps.ps_partkey
JOIN 
    SupplierData sd ON ps.ps_suppkey = sd.s_suppkey
WHERE 
    sb.name_length > 10
ORDER BY 
    sb.name_length DESC, 
    sd.s_name ASC
LIMIT 100;
