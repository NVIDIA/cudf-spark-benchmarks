SELECT
    SUM(l_extendedprice * (1 - l_discount)) AS revenue,
    n_name,
    extract(YEAR FROM o_orderdate) AS year
FROM
    customer c
JOIN
    orders o ON c.c_custkey = o.o_custkey
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    nation n ON c.c_nationkey = n.n_nationkey
GROUP BY
    n_name, year
ORDER BY
    year, revenue DESC;
