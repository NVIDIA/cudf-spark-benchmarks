SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    r.r_name AS region_name
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate >= DATE '1995-01-01'
    AND o.o_orderdate < DATE '1996-01-01'
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, r.r_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000000
ORDER BY 
    revenue DESC, avg_supplier_balance DESC
LIMIT 100;