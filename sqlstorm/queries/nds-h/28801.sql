WITH part_supplier_data AS (
    SELECT
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        CONCAT(p.p_name, ' - ', s.s_name) AS part_supplier_combination,
        UPPER(SUBSTRING(p.p_comment, 1, 10)) AS short_comment,
        LENGTH(p.p_comment) AS comment_length
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
region_nation_data AS (
    SELECT
        r.r_name AS region_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM
        region r
    JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY
        r.r_name, n.n_name
),
final_benchmark AS (
    SELECT
        p.part_supplier_combination,
        r.region_name,
        r.nation_name,
        p.short_comment,
        p.comment_length,
        r.supplier_count,
        p.ps_supplycost * p.ps_availqty AS total_supply_value
    FROM
        part_supplier_data p
    JOIN
        region_nation_data r ON r.supplier_count > 5
    WHERE
        p.ps_availqty > 100 AND p.comment_length < 50
    ORDER BY
        total_supply_value DESC
)
SELECT
    DISTINCT
    fp.part_supplier_combination,
    fp.region_name,
    fp.nation_name,
    fp.total_supply_value
FROM
    final_benchmark fp
WHERE
    fp.supplier_count > 10
LIMIT 20;
