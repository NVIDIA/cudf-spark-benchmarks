
SELECT 
    CONCAT(c.c_name, ' from ', s.s_name) AS supplier_customer,
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(p.p_retailprice) AS avg_price,
    MAX(l.l_discount) AS max_discount,
    MIN(s.s_acctbal) AS min_supplier_balance,
    r.r_name AS region_name,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    LENGTH(p.p_comment) AS comment_length
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
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE 'N%'
GROUP BY 
    c.c_name, s.s_name, p.p_name, r.r_name, p.p_comment, s.s_acctbal
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC, region_name;
