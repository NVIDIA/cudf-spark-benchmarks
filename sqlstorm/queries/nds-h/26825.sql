
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    p.p_type, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice) AS avg_price, 
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
    CONCAT('Supplier: ', s.s_name, ', Order Priority: ', o.o_orderpriority) AS supplier_order_info
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
    p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100) 
    AND s.s_acctbal > 2000 
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31' 
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_type, s.s_name, o.o_orderpriority
HAVING 
    SUM(l.l_quantity) > 100 
ORDER BY 
    avg_price DESC, total_quantity ASC;
