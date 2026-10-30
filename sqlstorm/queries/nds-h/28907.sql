SELECT
    CONCAT(s.s_name, ' from ', n.n_name, ' supplies ', p.p_name) AS supplier_product_description,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity_supplied,
    AVG(l.l_extendedprice) AS avg_extended_price
FROM
    supplier s
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    lineitem l ON ps.ps_partkey = l.l_partkey AND s.s_suppkey = l.l_suppkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
WHERE
    p.p_type LIKE '%metal%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY
    s.s_name, n.n_name, p.p_name
HAVING
    SUM(l.l_quantity) > 100
ORDER BY
    total_quantity_supplied DESC;