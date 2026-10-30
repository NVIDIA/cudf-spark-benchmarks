SELECT 
    p.p_name, 
    SUM(CASE 
        WHEN l_returnflag = 'R' THEN l_quantity 
        ELSE 0 
    END) AS total_returned_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(s.s_acctbal) AS average_supplier_account_balance,
    CONCAT(
        'Product: ', p.p_name, 
        ', Total Returned Quantity: ', SUM(CASE WHEN l_returnflag = 'R' THEN l_quantity ELSE 0 END), 
        ', Number of Orders: ', COUNT(DISTINCT o.o_orderkey), 
        ', Average Supplier Balance: ', AVG(s.s_acctbal)
    ) AS detailed_info
FROM 
    part AS p 
JOIN 
    partsupp AS ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier AS s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    lineitem AS l ON p.p_partkey = l.l_partkey 
JOIN 
    orders AS o ON l.l_orderkey = o.o_orderkey 
WHERE 
    p.p_name LIKE '%widget%' 
GROUP BY 
    p.p_name
ORDER BY 
    total_returned_quantity DESC
LIMIT 10;
