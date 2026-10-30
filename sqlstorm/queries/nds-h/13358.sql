SELECT 
    p.p_partkey,
    p.p_name,
    sum(l.l_quantity) AS total_quantity,
    sum(l.l_extendedprice) AS total_extended_price,
    avg(l.l_discount) AS average_discount,
    avg(s.s_acctbal) AS average_supplier_balance
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    c.c_mktsegment = 'BUILDING'
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    total_quantity DESC
LIMIT 100;
