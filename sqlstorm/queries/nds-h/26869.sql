SELECT 
    CONCAT('Supplier: ', s.s_name, ' (Key: ', s.s_suppkey, ')') AS supplier_info,
    CONCAT('Customer: ', c.c_name, ' (Key: ', c.c_custkey, ')') AS customer_info,
    CONCAT('Order ID: ', o.o_orderkey, ' | Status: ', CASE WHEN o.o_orderstatus = 'O' THEN 'Open' ELSE 'Closed' END) AS order_info,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(l.l_shipdate) AS last_ship_date,
    MIN(l.l_shipdate) AS first_ship_date,
    COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN o.o_orderkey END) AS total_returns,
    COUNT(DISTINCT CASE WHEN l.l_linestatus = 'F' THEN o.o_orderkey END) AS total_fulfilled_orders
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    c.c_mktsegment = 'BUILDING' 
    AND p.p_brand IN ('Brand#23', 'Brand#36') 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    s.s_suppkey, s.s_name, c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus
ORDER BY 
    total_revenue DESC, last_ship_date DESC;