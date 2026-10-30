
WITH StringBenchmarks AS (
    SELECT 
        p.p_name AS part_name, 
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        n.n_name AS nation_name,
        CONCAT(p.p_name, ' - ', s.s_name, ' - ', c.c_name) AS combined_info,
        UPPER(CONCAT(n.n_name, ' - ', s.s_name)) AS upper_nation_supplier,
        LOWER(REPLACE(c.c_comment, 'customer', 'client')) AS modified_customer_comment,
        LENGTH(c.c_name) AS customer_name_length,
        CHAR_LENGTH(s.s_comment) AS supplier_comment_length,
        SUBSTRING(p.p_comment, 1, 15) AS short_part_comment
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN customer c ON s.s_nationkey = c.c_nationkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE p.p_retailprice > 25.00
    AND c.c_acctbal < 1000.00
    ORDER BY LENGTH(p.p_name) DESC, c.c_name
)
SELECT
    part_name,
    supplier_name,
    customer_name,
    nation_name,
    combined_info,
    upper_nation_supplier,
    modified_customer_comment,
    customer_name_length,
    supplier_comment_length,
    short_part_comment
FROM StringBenchmarks
WHERE supplier_name IS NOT NULL
LIMIT 50;
