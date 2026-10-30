
WITH  String_Processing AS (
    SELECT 
        CONCAT('Supplier: ', s.s_name, 
               ' Address: ', s.s_address, 
               ' Nation: ', n.n_name, 
               ' Container: ', p.p_container) AS processed_string,
        s.s_suppkey,
        LENGTH(CONCAT('Supplier: ', s.s_name, 
                      ' Address: ', s.s_address, 
                      ' Nation: ', n.n_name, 
                      ' Container: ', p.p_container)) AS string_length
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE LENGTH(s.s_comment) > 50
),
Aggregated_Strings AS (
    SELECT 
        s_suppkey,
        STRING_AGG(processed_string, ', ') AS aggregated_string,
        SUM(string_length) AS total_length
    FROM String_Processing
    GROUP BY s_suppkey
)
SELECT 
    s_suppkey,
    aggregated_string,
    total_length,
    CHAR_LENGTH(aggregated_string) AS aggregated_length,
    (SELECT COUNT(*) FROM String_Processing) AS total_strings
FROM Aggregated_Strings
WHERE total_length > 1000
ORDER BY total_length DESC
LIMIT 10;
