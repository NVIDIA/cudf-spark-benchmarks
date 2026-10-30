SELECT
    n_name,
    COUNT(DISTINCT s_suppkey) AS supplier_count
FROM
    supplier s
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY
    n_name
ORDER BY
    supplier_count DESC;
