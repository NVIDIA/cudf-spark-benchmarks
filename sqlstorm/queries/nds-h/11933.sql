SELECT
    p.p_partkey,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    n.n_name AS nation_name,
    r.r_name AS region_name
FROM
    part p
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    l.l_shipdate >= DATE '1997-01-01'
    AND l.l_shipdate < DATE '1998-01-01'
GROUP BY
    p.p_partkey, p.p_name, n.n_name, r.r_name
ORDER BY
    revenue DESC
LIMIT 10;