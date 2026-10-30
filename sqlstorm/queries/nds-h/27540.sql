
SELECT 
    p.p_mfgr,
    COUNT(DISTINCT p.p_partkey) AS distinct_parts,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    r.r_name AS region_name
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_size > 10
    AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND n.n_name LIKE '%USA%'
GROUP BY p.p_mfgr, r.r_name, p.p_comment
HAVING COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY total_revenue DESC, p.p_mfgr ASC;
