SELECT
    l_orderkey,
    SUM(l_extendedprice * (1 - l_discount)) AS revenue,
    o_orderdate
FROM
    lineitem
JOIN
    orders ON lineitem.l_orderkey = orders.o_orderkey
WHERE
    l_shipdate >= '1997-01-01'
GROUP BY
    l_orderkey, o_orderdate
ORDER BY
    revenue DESC
LIMIT 100;