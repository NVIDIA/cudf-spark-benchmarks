SELECT
    p.p_name,
    p.p_brand,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS average_price,
    COUNT(DISTINCT l.l_orderkey) AS total_orders
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    p.p_size BETWEEN 10 AND 20
    AND r.r_name LIKE 'Europe%'
    AND o.o_orderstatus = 'O'
    AND l.l_shipmode IN ('AIR', 'TRUCK')
GROUP BY
    p.p_name, p.p_brand
HAVING
    SUM(ps.ps_availqty) > 500
ORDER BY
    average_price DESC;
