SELECT
    n.n_name,
    sum(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM
    customer c
JOIN
    orders o ON c.c_custkey = o.o_custkey
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY
    n.n_name
ORDER BY
    revenue DESC
LIMIT 10;
