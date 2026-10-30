
SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    CONCAT_WS(' ', s.s_address, s.s_comment) AS supplier_details, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount, 
    MAX(l.l_shipdate) AS latest_ship_date, 
    MIN(l.l_shipdate) AS earliest_ship_date, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders
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
    s.s_nationkey IN (
        SELECT n.n_nationkey 
        FROM nation n 
        WHERE n.n_name LIKE 'United%')
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, s.s_address, s.s_comment
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    avg_price_after_discount DESC, total_quantity ASC;
