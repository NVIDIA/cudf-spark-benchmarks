SELECT
    l.l_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM
    lineitem l
WHERE
    l.l_shipdate >= '1994-01-01' AND l.l_shipdate <= '1994-12-31'
GROUP BY
    l.l_orderkey
ORDER BY
    revenue DESC
LIMIT 10;
