WITH String_Processed AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CONCAT(p.p_mfgr, ' - ', p.p_brand) AS mfgr_brand,
        LENGTH(REPLACE(p.p_comment, ' ', '')) AS comment_length,
        SUBSTRING(p.p_name, 1, 10) AS short_name,
        UPPER(p.p_type) AS upper_type,
        LOWER(p.p_container) AS lower_container
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
)
SELECT 
    sp.p_partkey,
    sp.p_name,
    sp.mfgr_brand,
    sp.comment_length,
    sp.short_name,
    sp.upper_type,
    sp.lower_container,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    String_Processed sp
LEFT JOIN 
    partsupp ps ON sp.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem l ON l.l_partkey = sp.p_partkey
LEFT JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
GROUP BY 
    sp.p_partkey, sp.p_name, sp.mfgr_brand, sp.comment_length, sp.short_name, sp.upper_type, sp.lower_container
ORDER BY 
    sp.comment_length DESC, supplier_count DESC, order_count DESC
LIMIT 100;
