SELECT 
    p.p_name,
    s.s_name,
    CONCAT(s.s_address, ', ', n.n_name, ', ', r.r_name) AS supplier_address,
    p.p_retailprice,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_sales
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
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_name LIKE '%widget%'
    AND o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND s.s_acctbal > 1000
GROUP BY 
    p.p_name, s.s_name, s.s_address, n.n_name, r.r_name, p.p_retailprice
ORDER BY 
    order_count DESC, total_quantity DESC;