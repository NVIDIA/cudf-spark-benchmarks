SELECT 
    p.p_name AS ProductName,
    s.s_name AS SupplierName,
    COUNT(DISTINCT c.c_custkey) AS UniqueCustomers,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales,
    SUBSTRING(p.p_comment FROM 1 FOR 15) AS ShortComment,
    r.r_name AS RegionName
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size > 10 AND 
    l.l_shipmode IN ('AIR', 'GROUND') AND 
    o.o_orderdate >= DATE '1997-01-01'
GROUP BY 
    p.p_name, s.s_name, ShortComment, r.r_name
ORDER BY 
    TotalSales DESC, UniqueCustomers DESC
LIMIT 10;