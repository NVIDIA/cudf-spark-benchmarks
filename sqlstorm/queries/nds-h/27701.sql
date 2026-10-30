SELECT 
    part.p_name, 
    supplier.s_name, 
    COUNT(DISTINCT orders.o_orderkey) AS order_count,
    SUM(lineitem.l_extendedprice) AS total_revenue,
    SUM(CASE WHEN lineitem.l_discount > 0 THEN lineitem.l_extendedprice * lineitem.l_discount END) AS total_discounted_revenue,
    CONCAT('Supplier ', supplier.s_name, ' provides ', part.p_name, ' with an order count of ', COUNT(DISTINCT orders.o_orderkey), ' and a total revenue of ', SUM(lineitem.l_extendedprice)) AS summary
FROM 
    part
JOIN 
    partsupp ON part.p_partkey = partsupp.ps_partkey
JOIN 
    supplier ON partsupp.ps_suppkey = supplier.s_suppkey
JOIN 
    lineitem ON part.p_partkey = lineitem.l_partkey
JOIN 
    orders ON lineitem.l_orderkey = orders.o_orderkey
WHERE 
    lineitem.l_shipdate BETWEEN '1996-01-01' AND '1997-12-31'
    AND orders.o_orderstatus = 'O'
    AND lineitem.l_returnflag = 'N'
GROUP BY 
    part.p_name, supplier.s_name
HAVING 
    SUM(lineitem.l_extendedprice) > 10000
ORDER BY 
    total_revenue DESC;