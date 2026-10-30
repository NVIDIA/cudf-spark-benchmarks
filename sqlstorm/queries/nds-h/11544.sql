SELECT 
    l.l_returnflag, 
    l.l_linestatus, 
    SUM(l.l_quantity) AS sum_quantity, 
    SUM(l.l_extendedprice) AS sum_extendedprice, 
    SUM(l.l_discount) AS sum_discount, 
    COUNT(*) AS order_count
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate >= DATE '1995-01-01' AND 
    l.l_shipdate < DATE '1996-01-01' AND 
    r.r_name = 'ASIA'
GROUP BY 
    l.l_returnflag, 
    l.l_linestatus
ORDER BY 
    l.l_returnflag, 
    l.l_linestatus;
