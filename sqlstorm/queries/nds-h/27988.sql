
WITH String_Benchmark AS (
    SELECT
        p.p_name AS part_name,
        s.s_name AS supplier_name,
        CONCAT('Supplier ', s.s_name, ' provides ', p.p_name, ' in region ', r.r_name) AS benchmark_string,
        LENGTH(CONCAT('Supplier ', s.s_name, ' provides ', p.p_name, ' in region ', r.r_name)) AS string_length,
        REPLACE(REPLACE(REPLACE(CONCAT('Supplier ', s.s_name, ' provides ', p.p_name, ' in region ', r.r_name), ' ', '-'), ',', ''), '.', '') AS processed_string,
        CHAR_LENGTH(REPLACE(REPLACE(REPLACE(CONCAT('Supplier ', s.s_name, ' provides ', p.p_name, ' in region ', r.r_name), ' ', '-'), ',', ''), '.', '')) AS processed_length
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    WHERE
        p.p_retailprice > 20.00 AND s.s_acctbal > 500.00
    ORDER BY
        string_length DESC
    LIMIT 100
)

SELECT 
    part_name,
    supplier_name,
    benchmark_string,
    string_length,
    processed_string,
    processed_length
FROM 
    String_Benchmark;
