
SELECT 
    SUBSTRING(p.p_name, 1, 10) AS part_name_short,
    CONCAT(s.s_name, ' ', s.s_address) AS supplier_details,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_quantity) AS avg_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    MAX(l.l_shipdate) AS last_ship_date
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_type LIKE '%metal%'
    AND o.o_orderdate >= '1997-01-01'
GROUP BY 
    p.p_partkey, p.p_name, s.s_suppkey, s.s_name, s.s_address, 
    r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC
LIMIT 10;
