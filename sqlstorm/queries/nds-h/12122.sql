SELECT
    l_shipmode,
    COUNT(*) AS count
FROM
    lineitem
WHERE
    l_shipdate >= '1995-01-01'
    AND l_shipdate < '1996-01-01'
GROUP BY
    l_shipmode
ORDER BY
    count DESC;
