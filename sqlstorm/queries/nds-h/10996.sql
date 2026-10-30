SELECT
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    o_orderpriority
FROM
    orders o
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE
    o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
GROUP BY
    o_orderpriority
ORDER BY
    total_revenue DESC;