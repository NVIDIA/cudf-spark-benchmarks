SELECT
    l_orderkey,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    COUNT(DISTINCT l_partkey) AS unique_parts
FROM
    lineitem
WHERE
    l_shipdate >= '1997-01-01'
    AND l_shipdate < '1998-01-01'
GROUP BY
    l_orderkey
ORDER BY
    total_revenue DESC
LIMIT 10;