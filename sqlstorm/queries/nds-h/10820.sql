SELECT
    l_shipmode,
    COUNT(*) AS count_order
FROM
    lineitem
WHERE
    l_shipdate BETWEEN '1995-01-01' AND '1995-12-31'
GROUP BY
    l_shipmode
ORDER BY
    count_order DESC;