
SELECT 
    SUBSTRING(p.p_name, 1, 20) AS truncated_part_name,
    s.s_name AS supplier_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    r.r_name AS region_name,
    CONCAT('Supplier ', s.s_name, ' from ', n.n_name) AS supplier_info,
    CAST(AVG(CASE 
                WHEN l.l_returnflag = 'R' THEN l.l_quantity
                ELSE NULL 
            END) AS DECIMAL(10,2)) AS avg_returned_quantity
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_comment LIKE '%special%'
GROUP BY 
    p.p_name, s.s_name, n.n_name, r.r_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
ORDER BY 
    total_revenue DESC;
