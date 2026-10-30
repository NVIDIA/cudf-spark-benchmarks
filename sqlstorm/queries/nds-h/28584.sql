
SELECT
    p.p_name,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CONCAT('Supplier: ', s.s_name, ' - Region: ', r.r_name) AS supplier_region
FROM
    part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
WHERE
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND p.p_retailprice > 100
GROUP BY
    p.p_name, p.p_comment, s.s_name, r.r_name
HAVING
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY
    total_revenue DESC;
