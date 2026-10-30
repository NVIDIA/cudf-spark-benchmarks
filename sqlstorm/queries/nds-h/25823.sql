SELECT
    p.p_name,
    s.s_name,
    r.r_name,
    CONCAT('Supplier: ', s.s_name, ', Product: ', p.p_name) AS product_info,
    LENGTH(p.p_comment) AS comment_length,
    TRIM(UPPER(p.p_type)) AS upper_trimmed_type,
    SUBSTRING(p.p_comment, 1, 15) AS short_comment,
    REPLACE(REPLACE(p.p_comment, 'good', 'excellent'), 'bad', 'poor') AS updated_comment,
    CASE
        WHEN p.p_size BETWEEN 1 AND 10 THEN 'Small'
        WHEN p.p_size BETWEEN 11 AND 20 THEN 'Medium'
        ELSE 'Large'
    END AS size_category
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
    LOWER(p.p_name) LIKE '%widget%'
    AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
ORDER BY
    r.r_name, p.p_name;
