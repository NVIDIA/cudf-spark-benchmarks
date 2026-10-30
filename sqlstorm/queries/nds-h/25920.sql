SELECT 
    CONCAT(s.s_name, ' supplies ', p.p_name) AS Supplier_Product,
    SUM(l.l_quantity) AS Total_Quantity_Supplied,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS Average_Sale_Value,
    COUNT(DISTINCT o.o_orderkey) AS Unique_Orders,
    MAX(l.l_shipdate) AS Latest_Shipment,
    MIN(l.l_shipdate) AS Earliest_Shipment
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
    AND l.l_returnflag = 'N'
    AND o.o_orderstatus = 'O'
GROUP BY 
    s.s_name, p.p_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    Total_Quantity_Supplied DESC, Average_Sale_Value ASC;
