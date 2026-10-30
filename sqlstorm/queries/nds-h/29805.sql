
SELECT 
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_effective_price,
    MAX(l.l_shipdate) AS last_shipdate,
    (SELECT COUNT(*) 
     FROM supplier s 
     WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE '%land%')) AS total_suppliers_land,
    TRIM(BOTH ' ' FROM p.p_comment) AS trimmed_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_type LIKE '%plastic%'
    AND o.o_orderdate BETWEEN '1995-01-01' AND '1995-12-31'
GROUP BY 
    p.p_name,
    TRIM(BOTH ' ' FROM p.p_comment)
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    avg_effective_price DESC;
