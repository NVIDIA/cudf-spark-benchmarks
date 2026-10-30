SELECT
    s_name,
    SUM(ps_supplycost * ps_availqty) AS total_cost
FROM
    supplier s
JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
WHERE
    p_size > 10
GROUP BY
    s_name
ORDER BY
    total_cost DESC
LIMIT 10;
