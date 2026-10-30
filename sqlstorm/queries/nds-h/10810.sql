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
    l.l_shipdate >= '1996-01-01' AND l.l_shipdate < '1997-01-01'
GROUP BY
    l.l_orderkey, o.o_orderdate, o.o_orderpriority
ORDER BY
    revenue DESC
LIMIT 100;