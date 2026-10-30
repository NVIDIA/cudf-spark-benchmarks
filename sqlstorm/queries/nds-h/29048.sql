
SELECT
    CONCAT(p.p_name, ' - ', s.s_name) AS product_supplier,
    SUBSTRING(p.p_comment, 1, 15) AS short_comment,
    ROUND(AVG(l.l_extendedprice * (1 - l.l_discount)), 2) AS avg_price_after_discount,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    REPLACE(n.n_name, 'NATION', 'Nation') AS formatted_nation,
    LENGTH(p.p_type) AS type_length,
    TRIM(p.p_brand) AS cleaned_brand
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
JOIN
    customer c ON o.o_custkey = c.c_custkey
JOIN
    nation n ON c.c_nationkey = n.n_nationkey
WHERE
    p.p_retailprice > 50.00
    AND s.s_acctbal > 1000.00
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY
    p.p_name, s.s_name, p.p_comment, n.n_name, p.p_brand, p.p_type
ORDER BY
    avg_price_after_discount DESC, formatted_nation ASC;
