WITH StringBenchmark AS (
    SELECT 
        p_name,
        s_name,
        c_name,
        n_name,
        r_name,
        CONCAT(
            'Part: ', p_name, 
            ', Supplier: ', s_name, 
            ', Customer: ', c_name, 
            ', Nation: ', n_name, 
            ', Region: ', r_name
        ) AS full_description
    FROM 
        part 
        JOIN partsupp ON p_partkey = ps_partkey
        JOIN supplier ON ps_suppkey = s_suppkey
        JOIN customer ON s_nationkey = c_nationkey
        JOIN nation ON c_nationkey = n_nationkey
        JOIN region ON n_regionkey = r_regionkey
    WHERE 
        p_name LIKE '%widget%' 
        AND s_comment IS NOT NULL
        AND LENGTH(c_name) > 5
)
SELECT 
    full_description,
    LENGTH(full_description) AS description_length,
    SUBSTRING(full_description, 1, 50) AS short_description,
    REPLACE(full_description, ' ', '|') AS pipe_separated_description
FROM 
    StringBenchmark
ORDER BY 
    description_length DESC
LIMIT 10;
