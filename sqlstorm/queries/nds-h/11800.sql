SELECT
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_revenue
FROM
    part AS p
JOIN
    lineitem AS l ON p.p_partkey = l.l_partkey
JOIN
    partsupp AS ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier AS s ON ps.ps_suppkey = s.s_suppkey
JOIN
    nation AS n ON s.s_nationkey = n.n_nationkey
JOIN
    region AS r ON n.n_regionkey = r.r_regionkey
WHERE
    r.r_name = 'ASIA'
GROUP BY
    p.p_name
ORDER BY
    total_revenue DESC
LIMIT 10;
