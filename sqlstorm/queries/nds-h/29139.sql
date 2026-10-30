
WITH processed_parts AS (
    SELECT 
        p.p_partkey,
        UPPER(p.p_name) AS upper_p_name,
        LENGTH(p.p_comment) AS comment_length,
        CONCAT('Brand: ', p.p_brand, ', Type: ', p.p_type) AS brand_type,
        REPLACE(p.p_comment, 'very', 'extremely') AS modified_comment
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 20
),
supplier_accounts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal >= 10000 THEN 'High Value'
            WHEN s.s_acctbal >= 5000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS acctbal_category
    FROM 
        supplier s
)
SELECT 
    pp.upper_p_name,
    pp.comment_length,
    pp.brand_type,
    sa.s_name,
    sa.acctbal_category
FROM 
    processed_parts pp
JOIN 
    partsupp ps ON pp.p_partkey = ps.ps_partkey
JOIN 
    supplier_accounts sa ON ps.ps_suppkey = sa.s_suppkey
WHERE 
    pp.modified_comment LIKE '%extremely%'
ORDER BY 
    pp.comment_length DESC, sa.s_acctbal DESC
LIMIT 100;
