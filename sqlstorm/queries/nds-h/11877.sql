SELECT
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    o_orderdate,
    l_shipmode
FROM
    lineitem
JOIN
    orders ON lineitem.l_orderkey = orders.o_orderkey
WHERE
    l_shipdate >= '1997-01-01' AND l_shipdate < '1998-01-01'
GROUP BY
    o_orderdate, l_shipmode
ORDER BY
    total_revenue DESC
LIMIT 10;