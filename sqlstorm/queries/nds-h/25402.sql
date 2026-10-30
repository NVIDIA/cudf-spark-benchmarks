SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_key,
    l.l_quantity AS quantity,
    l.l_extendedprice AS extended_price,
    CASE 
        WHEN l.l_discount > 0 THEN 'Discounted'
        ELSE 'Regular Price'
    END AS pricing_type,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name) AS supplier_part_info,
    REPLACE(c.c_address, 'Street', 'St') AS modified_address,
    LEFT(o.o_comment, 30) AS short_order_comment
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    c.c_mktsegment = 'BUILDING'
    AND l.l_shipmode IN ('AIR', 'FOB')
ORDER BY 
    l.l_extendedprice DESC
LIMIT 10;
