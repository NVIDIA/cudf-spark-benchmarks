SELECT 
    CONCAT(c.c_name, ' (', s.s_name, ')') AS SupplierCustomer,
    p.p_name AS PartName,
    SUM(l.l_quantity) AS TotalQuantity,
    AVG(l.l_extendedprice) AS AvgExtendedPrice,
    MAX(l.l_discount) AS MaxDiscount,
    MIN(l.l_tax) AS MinTax,
    COUNT(DISTINCT o.o_orderkey) AS UniqueOrders,
    CASE 
        WHEN AVG(l.l_extendedprice) > 1000 THEN 'High Value'
        ELSE 'Regular Value'
    END AS PricingCategory
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
    part p ON l.l_partkey = p.p_partkey
GROUP BY 
    c.c_name, s.s_name, p.p_name
HAVING 
    SUM(l.l_quantity) > 500
ORDER BY 
    TotalQuantity DESC, AvgExtendedPrice DESC;
