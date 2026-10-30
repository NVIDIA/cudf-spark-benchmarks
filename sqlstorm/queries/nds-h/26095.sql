SELECT
    p.p_name,
    s.s_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    MAX(l.l_discount) AS max_discount,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    CONCAT('Supplier ', s.s_name, ' provides ', p.p_name, ' with avg price: ', ROUND(AVG(l.l_extendedprice), 2), ' and max discount ', MAX(l.l_discount), ' over ', COUNT(DISTINCT o.o_orderkey), ' orders.') AS summary
FROM
    lineitem l
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
WHERE
    o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    AND s.s_acctbal > 1000.00
GROUP BY
    p.p_name, s.s_name
HAVING
    SUM(l.l_quantity) > 100
ORDER BY
    total_quantity DESC;