
SELECT 
    CONCAT(s.s_name, ' from ', n.n_name, ' in ', r.r_name) AS supplier_location, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(l.l_extendedprice) AS avg_extended_price, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    s.s_comment LIKE '%reliable%' 
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    s.s_name, n.n_name, r.r_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_orders DESC;
