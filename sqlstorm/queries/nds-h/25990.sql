
SELECT
    p.p_name,
    s.s_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_extendedprice) AS avg_price,
    CONCAT('Region: ', r.r_name, ' - Nationality: ', n.n_name) AS location_info,
    SUBSTRING(p.p_comment, 1, 10) AS brief_comment,
    CHAR_LENGTH(p.p_comment) AS comment_length,
    LOWER(p.p_name) AS lowercase_name,
    UPPER(s.s_name) AS uppercase_supplier,
    LEFT(s.s_address, POSITION(',' IN s.s_address) - 1) AS city_name
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    p.p_retailprice > 100.00
    AND l.l_discount < 0.05
    AND o.o_orderstatus = 'O'
GROUP BY
    p.p_name,
    s.s_name,
    r.r_name,
    n.n_name,
    p.p_comment,
    s.s_address
HAVING
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY
    avg_price DESC
LIMIT 50;
