
SELECT 
    p.p_name,
    CONCAT(s.s_name, '(', s.s_phone, ')') AS SupplierInfo,
    SUBSTRING(p.p_comment, 1, 20) AS BriefComment,
    COUNT(DISTINCT o.o_orderkey) AS OrderCount,
    SUM(l.l_quantity) AS TotalQuantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
    AVG(l.l_tax) AS AverageTax
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_name LIKE '%tire%'
    AND s.s_acctbal > 5000
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, s.s_phone, p.p_comment
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    TotalRevenue DESC
LIMIT 10;
