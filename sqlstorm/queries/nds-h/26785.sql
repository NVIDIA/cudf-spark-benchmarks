SELECT 
    CONCAT('Region: ', r.r_name, ' | Supplier: ', s.s_name, ' | Customer: ', c.c_name, 
           ' | Order Date: ', CAST(o.o_orderdate AS STRING), ' | Total Price: $', 
           CAST(o.o_totalprice AS STRING), ' | Product Name: ', p.p_name) AS detailed_info
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
    p.p_name LIKE '%rubber%' 
    AND o.o_orderdate >= '1997-01-01' 
    AND o.o_orderdate <= '1997-12-31'
ORDER BY 
    r.r_name, s.s_name, o.o_orderdate DESC;