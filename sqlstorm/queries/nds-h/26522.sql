WITH String_Benchmark AS (
    SELECT
        p.p_partkey,
        CONCAT(p.p_name, ' - ', p.p_comment) AS part_info,
        LENGTH(CONCAT(p.p_name, ' - ', p.p_comment)) AS length_info,
        UPPER(p.p_name) AS upper_name,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment,
        REPLACE(p.p_comment, 'good', 'excellent') AS modified_comment
    FROM
        part p
    WHERE
        p.p_size BETWEEN 10 AND 20
),
Supplier_Aggregation AS (
    SELECT
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_name
)
SELECT
    sb.p_partkey,
    sb.part_info,
    sb.length_info,
    sa.s_name,
    sa.part_count,
    sa.total_supply_cost,
    CASE 
        WHEN sb.length_info > 50 THEN 'Long Name'
        ELSE 'Short Name'
    END AS name_length_category
FROM
    String_Benchmark sb
JOIN
    Supplier_Aggregation sa ON sb.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_name LIKE '%Corp%'))
ORDER BY
    sb.length_info DESC;
