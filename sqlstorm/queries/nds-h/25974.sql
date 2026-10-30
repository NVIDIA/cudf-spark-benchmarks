
SELECT 
    CONCAT(s.s_name, ' (', c.c_name, ')') AS supplier_customer,
    LEFT(p.p_name, 30) AS part_name,
    SUM(l.l_quantity) AS total_quantity,
    ROUND(SUM(l.l_extendedprice * (1 - l.l_discount)), 2) AS total_revenue,
    MAX(o.o_orderdate) AS last_order_date,
    r.r_name AS region_name
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
    p.p_name LIKE '%widget%'
    AND o.o_orderstatus = 'O'
    AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    s.s_name, c.c_name, p.p_name, r.r_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_revenue DESC, last_order_date DESC;
