
SELECT
    CONCAT(part.p_name, ' - ', supplier.s_name) AS part_supplier,
    COUNT(DISTINCT customer.c_custkey) AS unique_customers,
    SUM(lineitem.l_extendedprice * (1 - lineitem.l_discount)) AS total_revenue,
    region.r_name AS region_name,
    LEFT(part.p_comment, 10) AS comment_excerpt
FROM
    part
JOIN
    partsupp ON part.p_partkey = partsupp.ps_partkey
JOIN
    supplier ON partsupp.ps_suppkey = supplier.s_suppkey
JOIN
    lineitem ON part.p_partkey = lineitem.l_partkey
JOIN
    orders ON lineitem.l_orderkey = orders.o_orderkey
JOIN
    customer ON orders.o_custkey = customer.c_custkey
JOIN
    nation ON supplier.s_nationkey = nation.n_nationkey
JOIN
    region ON nation.n_regionkey = region.r_regionkey
WHERE
    lineitem.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND orders.o_orderstatus = 'F'
    AND part.p_container IN ('BOX', 'PACK')
GROUP BY
    part.p_name,
    supplier.s_name,
    region.r_name,
    part.p_comment
HAVING
    SUM(lineitem.l_extendedprice * (1 - lineitem.l_discount)) > 100000
ORDER BY
    total_revenue DESC,
    unique_customers ASC;
