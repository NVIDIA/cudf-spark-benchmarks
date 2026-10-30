SELECT
    p.p_partkey,
    p.p_name,
    sum(l.l_quantity) AS total_quantity,
    sum(l.l_extendedprice) AS total_revenue,
    s.s_name AS supplier_name,
    n.n_name AS nation_name
FROM
    part p
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY
    p.p_partkey, p.p_name, s.s_name, n.n_name
ORDER BY
    total_revenue DESC
LIMIT 10;
