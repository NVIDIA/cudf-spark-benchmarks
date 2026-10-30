
SELECT 
    CONCAT('Part: ', p.p_name, ' | Supplier: ', s.s_name, ' | Order Date: ', o.o_orderdate, 
           ' | Quantity: ', l.l_quantity, ' | Total Price: ', l.l_extendedprice) AS string_info,
    LENGTH(CONCAT('Part: ', p.p_name, ' | Supplier: ', s.s_name, ' | Order Date: ', o.o_orderdate, 
                  ' | Quantity: ', l.l_quantity, ' | Total Price: ', l.l_extendedprice)) AS string_length,
    COUNT(*) OVER(PARTITION BY r.r_regionkey) AS total_partitions 
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    part p ON l.l_partkey = p.p_partkey  
WHERE 
    r.r_name LIKE '%e%'
GROUP BY 
    p.p_name, s.s_name, o.o_orderdate, l.l_quantity, l.l_extendedprice, r.r_regionkey
ORDER BY 
    string_length DESC
LIMIT 100;
