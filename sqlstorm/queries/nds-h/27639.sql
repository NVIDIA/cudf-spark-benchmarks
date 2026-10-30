SELECT 
    p.p_name,
    s.s_name,
    substr(s.s_comment, 1, 20) AS short_comment,
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    AVG(l.l_extendedprice) AS avg_extended_price,
    MAX(l.l_discount) AS max_discount,
    MIN(l.l_tax) AS min_tax
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    p.p_name LIKE '%widget%' 
    AND s.s_acctbal > 1000.00
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, 
    s.s_name, 
    n.n_name, 
    r.r_name, 
    short_comment
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY 
    avg_extended_price DESC, 
    order_count ASC;