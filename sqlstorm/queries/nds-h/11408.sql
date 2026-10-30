SELECT
    l.l_shipmode,
    COUNT(*) AS count_order
FROM
    lineitem l
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
WHERE
    o.o_orderdate >= DATE '1996-01-01'
GROUP BY
    l.l_shipmode
ORDER BY
    count_order DESC;