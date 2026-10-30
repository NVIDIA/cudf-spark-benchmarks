
WITH StringBenchmark AS (
    SELECT 
        p.p_name,
        REPLACE(CONCAT(p.p_name, ' - ', s.s_name, ' (', c.c_name, ')'), ' ', '-') AS formatted_string,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE p.p_size BETWEEN 1 AND 10
      AND l.l_shipdate > DATE '1996-01-01'
    GROUP BY p.p_name, s.s_name, c.c_name
)
SELECT 
    formatted_string,
    total_price,
    LENGTH(formatted_string) AS string_length,
    CHAR_LENGTH(formatted_string) AS char_length,
    UPPER(formatted_string) AS uppercased_string,
    LOWER(formatted_string) AS lowercased_string
FROM StringBenchmark
ORDER BY total_price DESC
LIMIT 100;
