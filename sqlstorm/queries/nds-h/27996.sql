
SELECT 
    CONCAT(c.c_name, ' from ', s.s_name) AS supplier_customer,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
    r.r_name AS region_name,
    SUBSTRING(p.p_name, 1, 10) AS part_name_short,
    COUNT(DISTINCT o.o_orderkey) AS number_of_orders
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    r.r_name LIKE '%West%'
    AND o.o_orderdate >= DATE '1995-01-01'
GROUP BY 
    c.c_name, s.s_name, r.r_name, p.p_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_spent DESC;
