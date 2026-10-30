WITH StringBenchmark AS (
    SELECT 
        p.p_brand,
        CONCAT(p.p_name, ' - ', p.p_mfgr) AS full_description,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment,
        LENGTH(RTRIM(p.p_comment)) AS comment_length,
        REPLACE(UPPER(p.p_container), ' ', '_') AS formatted_container,
        TRIM(LEADING 'A' FROM p.p_type) AS trimmed_type,
        (SELECT COUNT(*) FROM supplier s WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE '%United%')) AS total_suppliers
    FROM 
        part p
    WHERE 
        LENGTH(p.p_name) > 5 
        AND p.p_retailprice BETWEEN 10.00 AND 500.00
)
SELECT 
    p_brand,
    COUNT(*) AS product_count,
    AVG(comment_length) AS avg_comment_length,
    MAX(formatted_container) AS max_container,
    MIN(trimmed_type) AS min_trimmed_type,
    SUM(total_suppliers) AS total_linked_suppliers
FROM 
    StringBenchmark
GROUP BY 
    p_brand
HAVING 
    COUNT(*) > 3
ORDER BY 
    product_count DESC;
