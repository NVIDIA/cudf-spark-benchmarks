SELECT
    k.n_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM
    lineitem l
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
JOIN
    nation k ON c.c_nationkey = k.n_nationkey
JOIN
    region r ON k.n_regionkey = r.r_regionkey
WHERE
    l.l_shipdate >= DATE '1995-01-01'
    AND l.l_shipdate < DATE '1996-01-01'
GROUP BY
    k.n_name
ORDER BY
    revenue DESC
LIMIT 10;
