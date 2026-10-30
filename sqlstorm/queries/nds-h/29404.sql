SELECT
    SUBSTRING(part.p_name, 1, 10) AS short_name,
    CONCAT(supplier.s_name, ' from ', nation.n_name) AS supplier_details,
    COUNT(DISTINCT orders.o_orderkey) AS total_orders,
    SUM(lineitem.l_extendedprice * (1 - lineitem.l_discount)) AS revenue,
    AVG(CASE 
            WHEN lineitem.l_returnflag = 'R' THEN 1 
            ELSE 0 
        END) AS return_rate
FROM
    part
JOIN
    partsupp ON part.p_partkey = partsupp.ps_partkey
JOIN
    supplier ON partsupp.ps_suppkey = supplier.s_suppkey
JOIN
    nation ON supplier.s_nationkey = nation.n_nationkey
JOIN
    lineitem ON part.p_partkey = lineitem.l_partkey
JOIN
    orders ON lineitem.l_orderkey = orders.o_orderkey
WHERE
    part.p_type LIKE '%plastic%'
AND
    orders.o_orderdate >= DATE '1997-01-01'
GROUP BY
    short_name, supplier_details
HAVING
    COUNT(DISTINCT orders.o_orderkey) > 10
ORDER BY
    revenue DESC;