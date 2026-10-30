SELECT 
    CONCAT(s.s_name, ' (', c.c_name, ')') AS supplier_customer,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice) AS total_revenue,
    ROUND(AVG(l.l_discount), 2) AS average_discount,
    SUBSTRING(p.p_name FROM 1 FOR 10) AS part_name_prefix,
    CASE 
        WHEN r.r_name LIKE '%NA%' THEN 'North America'
        WHEN r.r_name LIKE '%EU%' THEN 'Europe'
        ELSE 'Other Regions'
    END AS region_category
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate >= '1997-01-01' AND 
    o.o_orderdate < '1998-01-01' AND 
    l.l_returnflag = 'N'
GROUP BY 
    supplier_customer, part_name_prefix, region_category
ORDER BY 
    total_revenue DESC, total_orders ASC 
LIMIT 100;