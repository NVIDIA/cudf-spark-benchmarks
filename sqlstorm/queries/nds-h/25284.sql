
SELECT
    p.p_partkey,
    p.p_name,
    p.p_brand,
    CONCAT(SUBSTRING(p.p_name, 1, 10), '...', RIGHT(p.p_name, 10)) AS truncated_name,
    LENGTH(p.p_comment) AS comment_length,
    s.s_name AS supplier_name,
    s.s_phone AS supplier_phone,
    CASE
        WHEN s.s_acctbal > 1000 THEN 'High Value'
        WHEN s.s_acctbal BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS supplier_value_category,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price_per_item
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
WHERE
    p.p_size BETWEEN 1 AND 30
    AND s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
GROUP BY
    p.p_partkey, p.p_name, p.p_brand, s.s_name, s.s_phone, s.s_acctbal, LENGTH(p.p_comment)
HAVING
    SUM(l.l_quantity) > 50
ORDER BY
    total_quantity DESC, p.p_name ASC;
