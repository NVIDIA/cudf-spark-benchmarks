
WITH StringProcessing AS (
    SELECT 
        p.p_name AS part_name,
        s.s_name AS supplier_name,
        CONCAT('Supplier: ', s.s_name, ' provides part: ', p.p_name, 
               ' with price: $', CAST(ROUND(p.p_retailprice, 2) AS STRING), 
               ' and comment: ', p.p_comment) AS combined_info,
        LENGTH(CONCAT('Supplier: ', s.s_name, ' provides part: ', p.p_name, 
                      ' with price: $', CAST(ROUND(p.p_retailprice, 2) AS STRING), 
                      ' and comment: ', p.p_comment)) AS total_length
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_size >= 10
)
SELECT 
    part_name,
    supplier_name,
    combined_info,
    total_length
FROM StringProcessing
ORDER BY total_length DESC
LIMIT 10;
