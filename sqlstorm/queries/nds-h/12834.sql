SELECT
    l_shipmode,
    SUM(CASE WHEN l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count,
    SUM(l_quantity) AS total_quantity,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
FROM
    lineitem
WHERE
    l_shipdate >= DATE '1996-01-01' AND l_shipdate <= DATE '1996-12-31'
GROUP BY
    l_shipmode
ORDER BY
    l_shipmode;