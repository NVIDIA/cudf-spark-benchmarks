
SELECT 
    p.p_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS average_price,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    r.r_name AS region_name
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
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_retailprice > 100.00 
    AND l.l_shipdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
GROUP BY 
    p.p_name, r.r_name
HAVING 
    SUM(ps.ps_availqty) > 50
ORDER BY 
    average_price DESC, total_available_quantity DESC;
