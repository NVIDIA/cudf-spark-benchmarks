SELECT
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    n_name AS nation_name
FROM
    lineitem
JOIN
    orders ON lineitem.l_orderkey = orders.o_orderkey
JOIN
    customer ON orders.o_custkey = customer.c_custkey
JOIN
    supplier ON lineitem.l_suppkey = supplier.s_suppkey
JOIN
    nation ON supplier.s_nationkey = nation.n_nationkey
WHERE
    l_shipdate >= DATE '1997-01-01'
    AND l_shipdate < DATE '1997-02-01'
GROUP BY
    nation_name
ORDER BY
    total_revenue DESC
LIMIT 10;