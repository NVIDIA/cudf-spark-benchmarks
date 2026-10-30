SELECT
    l_orderkey,
    SUM(l_extendedprice) AS total_revenue,
    COUNT(DISTINCT l_partkey) AS distinct_parts,
    MAX(l_discount) AS max_discount,
    MIN(l_tax) AS min_tax
FROM
    lineitem
WHERE
    l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY
    l_orderkey
ORDER BY
    total_revenue DESC
LIMIT 100;