
SELECT 
    SUBSTRING(p.p_name FROM 1 FOR 10) AS short_name,
    r.r_name AS region_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    SUM(l.l_quantity) AS total_quantity,
    LEFT(c.c_name, 5) AS short_customer_name,
    o.o_orderdate AS order_date,
    CONCAT(s.s_name, ' - ', s.s_phone) AS supplier_contact_info
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
JOIN 
    customer c ON o.o_custkey = c.c_custkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
WHERE 
    p.p_comment LIKE '%fragile%' 
    AND o.o_orderstatus = 'O' 
    AND l.l_shipmode IN ('TRUCK', 'SHIP') 
GROUP BY 
    p.p_name, r.r_name, o.o_orderdate, c.c_name, s.s_name, s.s_phone 
ORDER BY 
    total_quantity DESC, average_supply_cost ASC;
