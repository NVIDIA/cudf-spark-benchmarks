SELECT
    c.c_name AS customer_name,
    o.o_orderkey AS order_key,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000 THEN 'High Value'
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS order_value_category,
    CONCAT(s.s_name, ' (', s.s_phone, ')') AS supplier_info,
    p.p_name AS part_name,
    COUNT(DISTINCT l.l_linenumber) AS line_item_count,
    r.r_name AS region_name
FROM
    customer c
JOIN
    orders o ON c.c_custkey = o.o_custkey
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    part p ON l.l_partkey = p.p_partkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND p.p_brand LIKE 'BrandA%'
GROUP BY
    c.c_name, o.o_orderkey, s.s_name, s.s_phone, p.p_name, r.r_name
HAVING
    COUNT(DISTINCT l.l_linenumber) > 1
ORDER BY
    total_price DESC;