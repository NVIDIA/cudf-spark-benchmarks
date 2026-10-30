SELECT 
    n.n_name AS Nation, 
    r.r_name AS Region, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
    COUNT(DISTINCT o.o_orderkey) AS OrderCount
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey 
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey 
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
WHERE 
    o.o_orderdate BETWEEN DATE '1994-01-01' AND DATE '1994-12-31' 
    AND l.l_shipmode IN ('AIR', 'TRUCK')
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    TotalRevenue DESC
LIMIT 10;