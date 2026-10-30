SELECT
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
FROM
    part p
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE
    s.s_nationkey IN (
        SELECT n.n_nationkey
        FROM nation n
        WHERE n.n_name = 'FRANCE'
    )
GROUP BY
    p.p_name
ORDER BY
    total_price DESC
LIMIT 10;
