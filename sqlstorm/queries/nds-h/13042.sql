SELECT
    l.l_suppkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    s.s_name,
    p.p_name
FROM
    lineitem l
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    part p ON l.l_partkey = p.p_partkey
WHERE
    l.l_shipdate >= DATE '1997-01-01'
    AND l.l_shipdate < DATE '1998-01-01'
GROUP BY
    l.l_suppkey, s.s_name, p.p_name
ORDER BY
    total_revenue DESC;