SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(p.p_retailprice) AS avg_retail_price,
    MAX(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE 0 END) AS max_return_price,
    MIN(CASE WHEN s.s_acctbal < 1000 THEN s.s_acctbal ELSE NULL END) AS min_account_balance
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
WHERE 
    p.p_name LIKE '%widget%'
    AND s.s_comment NOT LIKE '%bad supplier%'
    AND l.l_shipdate >= '1997-01-01'
    AND l.l_shipdate <= cast('1998-10-01' as date)
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_quantity DESC, avg_retail_price ASC;