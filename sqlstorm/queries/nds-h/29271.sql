SELECT 
    CONCAT('Supplier Name: ', s.s_name, 
           ', Part Name: ', p.p_name, 
           ', Available Quantity: ', ps.ps_availqty, 
           ', Total Price: ', ROUND(l.l_extendedprice * l.l_quantity, 2), 
           ', Nation: ', n.n_name) AS string_output
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    customer c ON l.l_orderkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_retailprice > 20.00 
    AND l.l_discount < 0.05 
    AND s.s_acctbal > 1000
ORDER BY 
    n.n_name, s.s_name;
