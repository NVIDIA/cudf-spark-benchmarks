SELECT
    p.p_partkey,
    p.p_name,
    sum(l.l_quantity) AS total_quantity,
    avg(l.l_extendedprice) AS avg_price,
    avg(l.l_discount) AS avg_discount
FROM
    part p
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    r.r_name = 'ASIA'
GROUP BY
    p.p_partkey, p.p_name
ORDER BY
    total_quantity DESC
LIMIT 100;
