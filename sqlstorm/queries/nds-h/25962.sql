SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(o.o_totalprice) AS average_order_price,
    MIN(l.l_shipdate) AS first_ship_date,
    MAX(NULLIF(l.l_receiptdate, '1900-01-01')) AS last_receipt_date,
    CONCAT('Supplier: ', s.s_name, ' | Part: ', p.p_name, ' | Available Qty: ', SUM(ps.ps_availqty), ' | Unique Customers: ', COUNT(DISTINCT c.c_custkey)) AS description
FROM 
    supplier s 
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_retailprice > 20.00 
    AND s.s_acctbal > 1000.00
    AND o.o_orderstatus = 'O'
GROUP BY 
    s.s_name, p.p_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_available_quantity DESC, average_order_price ASC;
