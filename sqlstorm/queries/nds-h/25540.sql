
SELECT
    CONCAT(c.c_name, ' from ', s.s_name, ' in ', r.r_name) AS supplier_customer_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    MAX(l.l_tax) AS max_tax
FROM
    customer c
JOIN
    orders o ON c.c_custkey = o.o_custkey
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    c.c_acctbal > 5000 AND
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' AND
    l.l_returnflag = 'N'
GROUP BY
    c.c_name, s.s_name, r.r_name
HAVING
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY
    total_quantity DESC, avg_extended_price ASC;
