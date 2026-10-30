WITH concatenated_names AS (
    SELECT
        p_partkey,
        CONCAT(p_name, ' - ', p_mfgr, ' - ', p_brand) AS full_description
    FROM
        part
),
filtered_parts AS (
    SELECT
        cn.p_partkey,
        cn.full_description,
        LENGTH(cn.full_description) AS description_length,
        SUM(ps.ps_availqty) AS total_available_quantity
    FROM
        concatenated_names cn
    JOIN
        partsupp ps ON cn.p_partkey = ps.ps_partkey
    WHERE
        UPPER(cn.full_description) LIKE '%STEEL%'
    GROUP BY
        cn.p_partkey, cn.full_description
),
ranked_parts AS (
    SELECT
        fp.p_partkey,
        fp.full_description,
        fp.description_length,
        fp.total_available_quantity,
        DENSE_RANK() OVER (ORDER BY fp.total_available_quantity DESC) AS rank
    FROM
        filtered_parts fp
)
SELECT
    rp.p_partkey,
    rp.full_description,
    rp.description_length,
    rp.total_available_quantity,
    rp.rank,
    CASE
        WHEN rp.rank <= 10 THEN 'TOP 10'
        ELSE 'OTHER'
    END AS ranking_category
FROM
    ranked_parts rp
WHERE
    rp.total_available_quantity > 0
ORDER BY
    rp.rank;
