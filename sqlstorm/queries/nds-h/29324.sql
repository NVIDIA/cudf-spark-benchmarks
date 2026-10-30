WITH  string_benchmark AS (
    SELECT p_name AS string_data,
           LENGTH(p_name) AS string_length,
           SUBSTRING(p_name FROM 1 FOR 10) AS substring_data,
           REPLACE(p_comment, 'obsolete', 'updated') AS modified_comment,
           CONCAT(s_name, ' ', s_address) AS supplier_info
    FROM part
    JOIN partsupp ON part.p_partkey = partsupp.ps_partkey
    JOIN supplier ON partsupp.ps_suppkey = supplier.s_suppkey
    WHERE p_size >= 10
    ORDER BY p_retailprice DESC
    LIMIT 100
),
analytics AS (
    SELECT COUNT(*) AS total_entries,
           AVG(string_length) AS avg_length,
           MIN(string_length) AS min_length,
           MAX(string_length) AS max_length
    FROM string_benchmark
)
SELECT sb.string_data,
       sb.string_length,
       sb.substring_data,
       sb.modified_comment,
       sb.supplier_info,
       a.total_entries,
       a.avg_length,
       a.min_length,
       a.max_length
FROM string_benchmark sb
CROSS JOIN analytics a
ORDER BY sb.string_length DESC;
