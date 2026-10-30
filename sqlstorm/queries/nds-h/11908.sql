SELECT
    l.l_shipmode,
    SUM(CASE WHEN l.l_discount = 0 THEN l.l_extendedprice ELSE 0 END) AS no_discount,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS with_discount,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM
    lineitem l
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
WHERE
    l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-12-31'
GROUP BY
    l.l_shipmode
ORDER BY
    total_orders DESC;