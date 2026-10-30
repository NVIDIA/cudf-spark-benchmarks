WITH PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_retailprice, 
        p.p_comment,
        SPLIT_PART(p.p_comment, ' ', 1) AS first_word_comment
    FROM 
        part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey,
        s.s_comment,
        LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
),
Combined AS (
    SELECT 
        pd.p_partkey,
        pd.p_name,
        pd.p_brand,
        COALESCE(NULLIF(sd.s_name, ''), 'UNKNOWN') AS supplier_name,
        COALESCE(NULLIF(sd.s_comment, ''), 'N/A') AS supplier_comment,
        sd.comment_length,
        pd.first_word_comment
    FROM 
        PartDetails pd
    LEFT JOIN 
        partsupp ps ON pd.p_partkey = ps.ps_partkey
    LEFT JOIN 
        SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
)
SELECT 
    first_word_comment, 
    COUNT(*) AS part_count, 
    AVG(comment_length) AS avg_supplier_comment_length
FROM 
    Combined
GROUP BY 
    first_word_comment
ORDER BY 
    part_count DESC
LIMIT 5;
