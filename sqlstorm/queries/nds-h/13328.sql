SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    ps.ps_supplycost, 
    ps.ps_availqty, 
    SUM(l.l_quantity) AS total_quantity, 
    SUM(l.l_extendedprice) AS total_extended_price
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    l.l_shipdate >= '1997-01-01' AND 
    l.l_shipdate <= '1997-12-31'
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    ps.ps_supplycost, 
    ps.ps_availqty
ORDER BY 
    total_extended_price DESC
LIMIT 100;