SELECT 
    p.p_name,
    s.s_name,
    n.n_name,
    c.c_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(o.o_totalprice) AS average_order_value,
    MAX(o.o_orderdate) AS last_order_date,
    CONCAT(s.s_name, ' from ', n.n_name, ' supplies ', p.p_name, ' with a total sold of ', ROUND(SUM(l.l_quantity), 2), ' units, generating a total sales amount of $', ROUND(SUM(l.l_extendedprice * (1 - l.l_discount)), 2), '.') AS detailed_report
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
GROUP BY 
    p.p_name, s.s_name, n.n_name, c.c_name
HAVING 
    SUM(l.l_quantity) > 1000
ORDER BY 
    total_sales DESC;
