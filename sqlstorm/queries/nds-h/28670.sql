
WITH string_benchmark AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        REPLACE(p.p_comment, 'old', 'new') AS updated_comment,
        CONCAT(SUBSTRING(p.p_name, 1, 10), '...', SUBSTRING(p.p_name, LENGTH(p.p_name) - 9, 10)) AS truncated_name,
        CHAR_LENGTH(p.p_name) AS name_length,
        CHAR_LENGTH(REPLACE(p.p_comment, ' ', '')) AS comment_length_no_spaces
    FROM 
        part p
    WHERE 
        p.p_size > 10
),
supplier_benchmark AS (
    SELECT 
        s.s_suppkey,
        UPPER(s.s_name) AS upper_supplier_name,
        LOWER(s.s_address) AS lower_supplier_address,
        CHAR_LENGTH(s.s_comment) AS supplier_comment_length
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
final_benchmark AS (
    SELECT 
        sb.p_partkey,
        sb.updated_comment,
        sb.truncated_name,
        sb.name_length,
        sb.comment_length_no_spaces,
        supp.upper_supplier_name,
        supp.lower_supplier_address,
        supp.supplier_comment_length
    FROM 
        string_benchmark sb
    JOIN 
        supplier_benchmark supp ON sb.p_partkey % 10 = supp.s_suppkey % 10
)
SELECT 
    f.p_partkey,
    f.truncated_name,
    f.updated_comment,
    f.upper_supplier_name,
    f.lower_supplier_address,
    f.name_length,
    f.comment_length_no_spaces,
    f.supplier_comment_length
FROM 
    final_benchmark f
ORDER BY 
    f.name_length DESC, f.supplier_comment_length ASC
LIMIT 100;
