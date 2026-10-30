SELECT
    n.n_name AS nation,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM
    orders o
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
JOIN
    nation n ON c.c_nationkey = n.n_nationkey
WHERE
    o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
GROUP BY
    n.n_name
ORDER BY
    total_revenue DESC
LIMIT 10;