SELECT
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    o_orderdate,
    c_mktsegment
FROM
    lineitem
JOIN
    orders ON lineitem.l_orderkey = orders.o_orderkey
JOIN
    customer ON orders.o_custkey = customer.c_custkey
WHERE
    l_shipdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
GROUP BY
    o_orderdate, c_mktsegment
ORDER BY
    total_revenue DESC
LIMIT 10;