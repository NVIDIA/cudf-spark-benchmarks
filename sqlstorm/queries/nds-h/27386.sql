
SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(p.p_retailprice) AS average_price, 
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    r.r_name AS region_name, 
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Total Qty: ', SUM(l.l_quantity)) AS summary
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
JOIN 
    customer c ON c.c_custkey = o.o_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, r.r_name, p.p_retailprice, p.p_comment
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    average_price DESC, total_quantity ASC;
