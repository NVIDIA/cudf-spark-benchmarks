SELECT 
    p.p_name,
    s.s_name,
    c.c_name AS customer_name,
    o.o_orderkey,
    o.o_orderdate,
    l.l_quantity,
    l.l_extendedprice,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name) AS supplier_part_info,
    REPLACE(LOWER(s.s_address), ' ', '-') AS formatted_address,
    CONCAT(o.o_orderpriority, ' Priority Order - ', o.o_orderstatus) AS order_priority,
    CASE 
        WHEN l.l_discount > 0 THEN 'Discounted' 
        ELSE 'Regular' 
    END AS pricing_type
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    p.p_retailprice > 50.00
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
ORDER BY 
    l.l_extendedprice DESC
LIMIT 100;