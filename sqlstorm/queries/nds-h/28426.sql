SELECT 
    CONCAT('Provider: ', s.s_name, ', Nation: ', n.n_name) AS SupplierInfo,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
    ROUND(AVG(l.l_quantity), 2) AS AverageQuantity,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS ReturnCount,
    ROUND(SUM(l.l_extendedprice * (1 - l.l_discount)) / NULLIF(COUNT(DISTINCT o.o_orderkey), 0), 2) AS AverageRevenuePerOrder
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    s.s_comment LIKE '%important%'
GROUP BY 
    s.s_name, n.n_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000000
ORDER BY 
    TotalRevenue DESC;
