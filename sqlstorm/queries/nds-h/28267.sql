SELECT 
    p.p_partkey,
    LOWER(REPLACE(p.p_name, ' ', '-')) AS formatted_name,
    CONCAT(p.p_brand, ' - ', p.p_mfgr) AS supplier_info,
    r.r_name AS region_name,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(l.l_extendedprice) AS average_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_size > 10 AND
    s.s_acctbal > 50000 AND
    o.o_orderstatus = 'O'
GROUP BY 
    p.p_partkey, formatted_name, supplier_info, region_name
ORDER BY 
    total_orders DESC, average_price ASC
LIMIT 100;
