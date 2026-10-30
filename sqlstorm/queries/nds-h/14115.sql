SELECT
    n_name,
    SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM
    nation
JOIN
    supplier ON nation.n_nationkey = supplier.s_nationkey
JOIN
    partsupp ON supplier.s_suppkey = partsupp.ps_suppkey
JOIN
    part ON partsupp.ps_partkey = part.p_partkey
JOIN
    lineitem ON part.p_partkey = lineitem.l_partkey
JOIN
    orders ON lineitem.l_orderkey = orders.o_orderkey
WHERE
    l_shipdate >= DATE '1995-01-01' AND l_shipdate < DATE '1996-01-01'
GROUP BY
    n_name
ORDER BY
    revenue DESC;
