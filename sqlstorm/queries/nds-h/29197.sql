
SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Type: ', p.p_type, 
           ', Available Quantity: ', ps.ps_availqty, ', Supply Cost: ', ps.ps_supplycost) AS detailed_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_extended_price
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
    s.s_name LIKE '%Inc%'
    AND p.p_size BETWEEN 10 AND 20
    AND l.l_discount > 0.1
GROUP BY 
    s.s_name, p.p_name, p.p_type, ps.ps_availqty, ps.ps_supplycost
HAVING 
    SUM(l.l_quantity) > 1000
ORDER BY 
    total_extended_price DESC;
