SELECT 
    p.p_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(o.o_totalprice) AS average_order_price,
    CONCAT('Part: ', p.p_name, ' supplied by ', COUNT(DISTINCT s.s_suppkey), ' suppliers with total available quantity of ', SUM(ps.ps_availqty), ' and average order price of $', ROUND(AVG(o.o_totalprice), 2)) AS detailed_info
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
WHERE 
    p.p_mfgr LIKE 'Manufacturer%'
    AND o.o_orderstatus = 'O'
    AND o.o_orderdate >= DATE '1997-01-01' 
GROUP BY 
    p.p_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    detailed_info;