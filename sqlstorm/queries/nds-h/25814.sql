
SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    CONCAT('Region: ', r.r_name, ', Nation: ', n.n_name) AS supplier_location,
    SUM(l.l_quantity) AS total_quantity_ordered, 
    AVG(l.l_discount) AS average_discount,
    MAX(l.l_extendedprice) AS max_price,
    MIN(l.l_extendedprice) AS min_price,
    COUNT(DISTINCT o.o_orderkey) AS unique_order_count
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
    p.p_mfgr LIKE '%Manufacturer%' 
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, r.r_name, n.n_name
HAVING 
    SUM(l.l_quantity) > 1000
ORDER BY 
    total_quantity_ordered DESC, average_discount ASC;
