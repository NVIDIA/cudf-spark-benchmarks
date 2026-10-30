SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(o.o_totalprice) AS total_sales,
    AVG(o.o_totalprice) AS average_order_value,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_extended_price,
    SUM(l.l_discount) AS total_discount,
    SUM(l.l_tax) AS total_tax
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate >= '1997-01-01' AND 
    o.o_orderdate < '1998-01-01' AND 
    l.l_returnflag = 'R'
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_sales DESC, total_customers ASC;