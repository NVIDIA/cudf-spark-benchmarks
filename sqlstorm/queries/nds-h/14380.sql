SELECT
    p.p_partkey,
    p.p_name,
    sum(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    n.n_name,
    r.r_name
FROM
    part AS p
JOIN
    lineitem AS l ON p.p_partkey = l.l_partkey
JOIN
    supplier AS s ON l.l_suppkey = s.s_suppkey
JOIN
    nation AS n ON s.s_nationkey = n.n_nationkey
JOIN
    region AS r ON n.n_regionkey = r.r_regionkey
WHERE
    l.l_shipdate >= DATE '1995-01-01'
    AND l.l_shipdate < DATE '1996-01-01'
GROUP BY
    p.p_partkey, p.p_name, n.n_name, r.r_name
ORDER BY
    revenue DESC
LIMIT 10;
