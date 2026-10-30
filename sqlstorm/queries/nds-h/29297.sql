SELECT 
    p.p_name,
    p.p_mfgr,
    CONCAT(p.p_type, ' (', p.p_brand, ')') AS product_info,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    MIN(s.s_acctbal) AS min_supplier_balance,
    MAX(s.s_acctbal) AS max_supplier_balance,
    AVG(CASE WHEN s.s_acctbal > 10000 THEN s.s_acctbal END) AS avg_high_balance_suppliers,
    SUM(CASE WHEN s.s_comment LIKE '%reliable%' THEN 1 ELSE 0 END) AS reliable_supplier_count,
    r.r_name AS region_name
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_size BETWEEN 1 AND 20
    AND p.p_retailprice > 50.00
GROUP BY p.p_name, p.p_mfgr, p.p_type, p.p_brand, r.r_name
HAVING COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY supplier_count DESC, max_supplier_balance DESC;
