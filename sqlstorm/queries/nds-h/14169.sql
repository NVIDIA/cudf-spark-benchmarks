SELECT
    l_shipmode,
    COUNT(*) AS cnt
FROM
    lineitem
WHERE
    l_shipdate >= DATE '1995-01-01' AND l_shipdate < DATE '1996-01-01'
GROUP BY
    l_shipmode
ORDER BY
    cnt DESC;
