SELECT 
    CONCAT('Supplier: ', s.s_name, ' | Part: ', p.p_name, 
           ' | Quantity Available: ', ps.ps_availqty, 
           ' | Total Price: ', ROUND(l.l_extendedprice * (1 - l.l_discount), 2),
           ' | Ship Mode: ', l.l_shipmode) AS benchmark_info
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    l.l_shipdate >= DATE '1997-01-01' 
    AND l.l_shipdate < DATE '1998-01-01'
    AND s.s_comment LIKE '%urgent%'
ORDER BY 
    l.l_shipmode, l.l_extendedprice DESC
LIMIT 100;