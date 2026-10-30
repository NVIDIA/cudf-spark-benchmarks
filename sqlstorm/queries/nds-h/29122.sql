SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_mfgr, 
    p.p_brand, 
    p.p_type, 
    p.p_size, 
    p.p_container, 
    p.p_retailprice, 
    ps.ps_supplycost, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    o.o_orderkey, 
    o.o_orderdate, 
    o.o_orderstatus,
    CASE 
        WHEN p.p_retailprice > 100 THEN 'High Value'
        ELSE 'Normal Value' 
    END AS price_category,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name) AS supplier_part_info,
    UPPER(SUBSTRING(p.p_comment, 1, 20)) AS comment_snippet,
    RANK() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rank_by_price
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
    o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND s.s_comment LIKE '%tocol%' 
ORDER BY 
    p.p_retailprice DESC, 
    supplier_part_info;