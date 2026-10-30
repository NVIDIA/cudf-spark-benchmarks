SELECT
    l.l_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    o.o_orderdate,
    o.o_orderpriority
FROM
    lineitem l
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
WHERE
    o.o_orderdate BETWEEN DATE '1994-01-01' AND DATE '1994-12-31'
GROUP BY
    l.l_orderkey, o.o_orderdate, o.o_orderpriority
ORDER BY
    revenue DESC;
