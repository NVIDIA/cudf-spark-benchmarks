SELECT
    nation.n_name,
    SUM(lineitem.l_extendedprice * (1 - lineitem.l_discount)) AS total_revenue
FROM
    lineitem
JOIN
    orders ON lineitem.l_orderkey = orders.o_orderkey
JOIN
    customer ON orders.o_custkey = customer.c_custkey
JOIN
    nation ON customer.c_nationkey = nation.n_nationkey
GROUP BY
    nation.n_name
ORDER BY
    total_revenue DESC
LIMIT 10;
