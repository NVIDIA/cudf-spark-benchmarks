SELECT
    p.p_partkey,
    p.p_name,
    SUM(lp.l_quantity) AS total_quantity,
    SUM(lp.l_extendedprice) AS total_revenue
FROM
    part p
JOIN
    lineitem lp ON p.p_partkey = lp.l_partkey
JOIN
    supplier s ON lp.l_suppkey = s.s_suppkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    r.r_name = 'ASIA'
GROUP BY
    p.p_partkey, p.p_name
ORDER BY
    total_revenue DESC
LIMIT 10;
