SELECT
    l_orderkey,
    SUM(l_extendedprice * (1 - l_discount)) AS total_sales,
    o_orderdate,
    COUNT(DISTINCT l_suppkey) AS supplier_count
FROM
    lineitem
JOIN
    orders ON lineitem.l_orderkey = orders.o_orderkey
WHERE
    l_shipdate >= DATE '1995-01-01' AND l_shipdate <= DATE '1995-12-31'
GROUP BY
    l_orderkey, o_orderdate
ORDER BY
    total_sales DESC
LIMIT 100;