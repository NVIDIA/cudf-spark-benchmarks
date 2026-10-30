SELECT
    n_name,
    SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM
    supplier s
JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
WHERE
    l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY
    n_name
ORDER BY
    revenue DESC
LIMIT 10;