SELECT
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM
    part p
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    supplier s ON s.s_suppkey = l.l_suppkey
JOIN
    partsupp ps ON ps.ps_partkey = p.p_partkey AND ps.ps_suppkey = s.s_suppkey
JOIN
    nation n ON n.n_nationkey = s.s_nationkey
WHERE
    n.n_name = 'FRANCE'
    AND l.l_shipdate >= DATE '1995-01-01'
    AND l.l_shipdate < DATE '1996-01-01'
GROUP BY
    p.p_name
ORDER BY
    revenue DESC;
