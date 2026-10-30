SELECT
    l.l_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    o.o_orderdate,
    o.o_orderstatus
FROM
    lineitem l
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
WHERE
    o.o_orderdate >= DATE '1995-01-01'
GROUP BY
    l.l_orderkey, o.o_orderdate, o.o_orderstatus
ORDER BY
    revenue DESC
LIMIT 100;
