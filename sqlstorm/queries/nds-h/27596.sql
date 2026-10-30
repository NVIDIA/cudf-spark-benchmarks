SELECT 
    p.p_name, 
    CONCAT('Manufacturer: ', p.p_mfgr, ', Brand: ', p.p_brand, ', Type: ', p.p_type) AS part_details, 
    SUM(CASE 
            WHEN s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2) 
            THEN ps.ps_supplycost * ps.ps_availqty 
            ELSE 0 
        END) AS total_value_above_avg_supplier_balance,
    COUNT(DISTINCT CONCAT(c.c_name, ' (', c.c_address, ')')) AS distinct_customers 
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    customer c ON c.c_nationkey = s.s_nationkey 
JOIN 
    orders o ON o.o_custkey = c.c_custkey 
JOIN 
    lineitem l ON l.l_orderkey = o.o_orderkey 
WHERE 
    p.p_size BETWEEN 10 AND 20 
    AND s.s_comment LIKE '%quality%' 
GROUP BY 
    p.p_name, p.p_mfgr, p.p_brand, p.p_type 
ORDER BY 
    total_value_above_avg_supplier_balance DESC, 
    distinct_customers ASC;
