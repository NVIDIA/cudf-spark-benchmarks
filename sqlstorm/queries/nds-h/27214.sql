
SELECT 
    CONCAT('Supplier: ', s.s_name, ', Nation: ', n.n_name) AS supplier_details,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(o.o_totalprice) AS highest_order_value
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    s.s_name LIKE '%Supplier%' 
    AND o.o_orderstatus = 'O'
GROUP BY 
    s.s_name, n.n_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    average_supply_cost DESC, total_orders ASC;
