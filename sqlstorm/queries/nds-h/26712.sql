
SELECT DISTINCT
    LOWER(s.s_name) AS supplier_name,
    CONCAT('Supplier: ', LOWER(s.s_name), ', Region: ', r.r_name, ', Comment: ', SUBSTRING(s.s_comment, 1, 25)) AS supplier_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT p.p_partkey) AS total_parts_supplied
FROM
    supplier s
JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    s.s_comment LIKE '%urgent%'
    AND r.r_name IN (SELECT r_name FROM region WHERE r_comment LIKE '%logistics%')
GROUP BY
    supplier_name, supplier_info, s.s_suppkey, r.r_name
HAVING
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY
    total_revenue DESC, supplier_name;
