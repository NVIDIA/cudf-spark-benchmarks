WITH string_benchmark AS (
    SELECT 
        p.p_name,
        s.s_name,
        CONCAT('Part: ', p.p_name, ' | Supplier: ', s.s_name) AS combined_info,
        LENGTH(p.p_comment) AS comment_length,
        SUBSTRING(p.p_comment FROM 1 FOR 10) AS short_comment,
        UPPER(CONCAT(p.p_name, ' sold by ', s.s_name)) AS uppercased_info,
        TRIM(REPLACE(p.p_comment, ' ', '_')) AS underscored_comment,
        REPLACE(REPLACE(s.s_address, ' ', ''), ',', '') AS compact_address
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_retailprice > 50.00
    ORDER BY LENGTH(p.p_comment) DESC
    LIMIT 100
)
SELECT 
    combined_info,
    comment_length,
    short_comment,
    uppercased_info,
    underscored_comment,
    compact_address
FROM string_benchmark
WHERE short_comment LIKE 'A%';
