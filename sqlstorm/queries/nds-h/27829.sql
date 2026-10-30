SELECT 
    CONCAT(c.c_name, ' from ', s.s_name, ' supplied ', COUNT(DISTINCT l.l_orderkey), ' orders of ', p.p_name) AS order_summary,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    LOWER(REGEXP_REPLACE(r.r_name, '[^a-zA-Z]', '')) AS clean_region_name
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
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderstatus = 'O'
    AND p.p_retailprice > 100.00
GROUP BY 
    c.c_name, s.s_name, p.p_name, p.p_comment, r.r_name
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY 
    order_summary DESC
LIMIT 10;
