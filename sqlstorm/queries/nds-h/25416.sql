SELECT 
    p.p_name,
    LENGTH(p.p_name) AS name_length,
    LOWER(p.p_comment) AS normalized_comment,
    CONCAT('Supplier: ', s.s_name, ', Region: ', r.r_name) AS supplier_region,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > 100.00 
    AND s.s_acctbal > 1000.00
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, normalized_comment, supplier_region
ORDER BY 
    total_revenue DESC
LIMIT 10;