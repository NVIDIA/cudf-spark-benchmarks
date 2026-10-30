
SELECT 
    CONCAT('Supplier: ', s.s_name, ' (Nation: ', n.n_name, ') - ', 
           'Orders Count: ', COUNT(DISTINCT o.o_orderkey), 
           ', Total Extended Price: ', SUM(l.l_extendedprice), 
           ', Avg Discount: ', AVG(l.l_discount), 
           ' [Comment: ', s.s_comment, ']') AS supplier_summary
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    o.o_orderstatus = 'O' 
    AND l.l_shipdate >= '1997-01-01' 
    AND l.l_shipdate < '1998-01-01'
GROUP BY 
    s.s_suppkey, s.s_name, n.n_name, s.s_comment
ORDER BY 
    SUM(l.l_extendedprice) DESC
LIMIT 10;
