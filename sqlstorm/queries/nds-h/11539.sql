SELECT
    n.n_name AS nation_name,
    SUM(o.o_totalprice) AS total_revenue
FROM
    customer c
JOIN
    orders o ON c.c_custkey = o.o_custkey
JOIN
    nation n ON c.c_nationkey = n.n_nationkey
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE
    l.l_shipdate BETWEEN '1995-01-01' AND '1995-12-31'
GROUP BY
    n.n_name
ORDER BY
    total_revenue DESC;
