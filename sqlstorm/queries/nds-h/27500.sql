
SELECT 
    p.p_partkey,
    p.p_name,
    CONCAT('Brand: ', p.p_brand, ', Type: ', p.p_type, ', Container: ', p.p_container) AS part_details,
    COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    SUM(CASE 
            WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) 
            ELSE 0 
        END) AS total_revenue_returned,
    COUNT(DISTINCT CASE 
            WHEN c.c_mktsegment = 'BUILDING' THEN o.o_orderkey 
            END) AS building_segment_orders
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_comment LIKE '%plastic%'
    AND s.s_comment NOT LIKE '%premium%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_container
ORDER BY 
    total_available_quantity DESC, average_supply_cost ASC
LIMIT 100;
