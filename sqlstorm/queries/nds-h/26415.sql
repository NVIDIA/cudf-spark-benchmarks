SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    p.p_type,
    p.p_size,
    p.p_container,
    p.p_retailprice,
    p.p_comment,
    CONCAT(s.s_name, ' ', s.s_address) AS supplier_info,
    SUBSTR(s.s_comment, 1, 50) AS shortened_supplier_comment,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    ROUND(AVG(l.l_extendedprice), 2) AS avg_price,
    r.r_name AS region_name
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    customer c ON c.c_custkey = l.l_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size > 20
    AND s.s_acctbal > 1000.00
    AND l.l_shipdate BETWEEN '1995-01-01' AND '1997-01-01'
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, 
    p.p_container, p.p_retailprice, p.p_comment, s.s_suppkey, 
    s.s_name, s.s_address, s.s_comment, r.r_name
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY 
    avg_price DESC, total_quantity ASC
LIMIT 100;