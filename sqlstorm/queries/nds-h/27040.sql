
SELECT
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_mfgr,
    p.p_type,
    p.p_size,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey,
    COUNT(l.l_orderkey) AS lineitem_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    CONCAT('Part: ', p.p_name, ' | Brand: ', p.p_brand, ' | Mfgr: ', p.p_mfgr) AS part_details,
    CASE
        WHEN p.p_size < 20 THEN 'Small'
        WHEN p.p_size BETWEEN 20 AND 50 THEN 'Medium'
        ELSE 'Large'
    END AS size_category
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
WHERE
    p.p_comment LIKE '%special%'
    AND s.s_comment NOT LIKE '%discount%'
GROUP BY
    p.p_partkey, p.p_name, p.p_brand, p.p_mfgr, p.p_type, p.p_size, s.s_name, c.c_name, o.o_orderkey
HAVING
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY
    total_revenue DESC;
