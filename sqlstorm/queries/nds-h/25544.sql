SELECT 
    substr(c.c_name, 1, 10) AS short_name,
    p.p_name || ' ' || p.p_type AS full_part_name,
    r.r_name AS region_name,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_returned_value,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(CASE WHEN s.s_acctbal > 5000 THEN s.s_acctbal ELSE NULL END) AS average_supplier_balance,
    array_agg(DISTINCT s.s_name) AS supplier_names
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
    c.c_mktsegment = 'BUILDING' 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    c.c_name, p.p_name, p.p_type, r.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_returned_value DESC, short_name ASC;