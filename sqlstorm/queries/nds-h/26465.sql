SELECT 
    CONCAT('Supplier Name: ', s.s_name, 
           ', Part Name: ', p.p_name, 
           ', Order Total Price: ', ROUND(SUM(o.o_totalprice), 2), 
           ', Region: ', r.r_name, 
           ', Customer Segment: ', c.c_mktsegment) AS benchmark_string
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
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
    p.p_brand = 'Brand#23' AND 
    s.s_acctbal > 500.00 AND 
    o.o_orderstatus = 'F' 
GROUP BY 
    s.s_name, p.p_name, r.r_name, c.c_mktsegment
ORDER BY 
    benchmark_string DESC
LIMIT 100;
