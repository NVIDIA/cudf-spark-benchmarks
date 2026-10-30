SELECT
    p.p_partkey,
    p.p_name,
    s.s_suppkey,
    s.s_name,
    sum(l.l_quantity) AS total_quantity,
    sum(l.l_extendedprice) AS total_revenue
FROM
    lineitem l
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY
    p.p_partkey, p.p_name, s.s_suppkey, s.s_name
ORDER BY
    total_revenue DESC
LIMIT 10;
