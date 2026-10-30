SELECT 
    s.s_name, 
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
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
WHERE 
    o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
GROUP BY 
    s.s_name
ORDER BY 
    total_cost DESC
LIMIT 10;