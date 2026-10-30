SELECT 
    p.p_name AS PartName,
    s.s_name AS SupplierName,
    c.c_name AS CustomerName,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
    COUNT(DISTINCT o.o_orderkey) AS NumberOfOrders,
    LEFT(s.s_comment, 50) AS SupplierCommentSnippet,
    SUBSTRING(c.c_address, 1, 30) AS ShortCustomerAddress,
    CASE 
        WHEN s.s_acctbal > 10000 THEN 'High Account Balance'
        WHEN s.s_acctbal BETWEEN 5000 AND 10000 THEN 'Medium Account Balance'
        ELSE 'Low Account Balance'
    END AS AccountBalanceCategory
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    o.o_orderdate BETWEEN '1995-01-01' AND '1995-12-31'
    AND l.l_returnflag = 'N'
GROUP BY 
    p.p_name, s.s_name, c.c_name, s.s_comment, c.c_address, s.s_acctbal
ORDER BY 
    TotalRevenue DESC
LIMIT 10;