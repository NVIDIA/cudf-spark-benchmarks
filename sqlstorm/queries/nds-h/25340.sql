SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS average_discounted_price,
    COUNT(DISTINCT o.o_orderkey) AS number_of_orders,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 10 THEN 'High Demand'
        WHEN COUNT(DISTINCT o.o_orderkey) BETWEEN 5 AND 10 THEN 'Medium Demand'
        ELSE 'Low Demand'
    END AS demand_category
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
    s.s_comment LIKE '%special%'
    AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    s.s_name, p.p_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    average_discounted_price DESC, supplier_name;