SELECT 
    CONCAT(s.s_name, ' (', SUBSTRING(s.s_address, 1, 20), '...)') AS supplier_details,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(CASE 
        WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) 
        ELSE 0 
    END) AS average_returned_value,
    MAX(l.l_shipdate) AS last_ship_date
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
    s.s_acctbal > 0
    AND l.l_shipmode IN ('AIR', 'TRUCK')
    AND o.o_orderstatus = 'O'
GROUP BY 
    s.s_name, s.s_address
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC, last_ship_date DESC
LIMIT 10;
