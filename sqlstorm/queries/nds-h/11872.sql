SELECT 
    p.p_brand, 
    p.p_type, 
    avg(l.l_extendedprice) AS avg_price, 
    sum(l.l_quantity) AS total_quantity, 
    count(DISTINCT o.o_orderkey) AS order_count
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-10-01'
GROUP BY 
    p.p_brand, p.p_type
ORDER BY 
    avg_price DESC
LIMIT 100;