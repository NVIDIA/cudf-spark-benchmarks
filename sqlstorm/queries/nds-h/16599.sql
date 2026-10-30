SELECT
    l.l_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM
    lineitem l
WHERE
    l.l_shipdate >= DATE '1997-01-01'
    AND l.l_shipdate < DATE '1998-01-01'
GROUP BY
    l.l_orderkey
ORDER BY
    total_revenue DESC
LIMIT 10;