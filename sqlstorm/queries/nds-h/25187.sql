SELECT
    p.p_brand,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity,
    AVG(l.l_discount) AS average_discount,
    MAX(l.l_extendedprice) AS max_extended_price,
    MIN(CASE WHEN c.c_mktsegment = 'BUILDING' THEN l.l_extendedprice ELSE NULL END) AS min_building_price
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    lineitem l ON l.l_partkey = p.p_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
WHERE
    p.p_retailprice > 50.00
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY
    p.p_brand
HAVING
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY
    supplier_count DESC, average_discount ASC;