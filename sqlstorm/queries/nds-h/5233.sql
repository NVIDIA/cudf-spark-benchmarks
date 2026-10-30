
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(o.o_totalprice) AS total_orders_value,
    AVG(s.s_acctbal) AS avg_supplier_acctbal
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
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
WHERE 
    o.o_orderdate >= DATE '1994-01-01' 
    AND o.o_orderdate < DATE '1995-01-01'
    AND l.l_discount BETWEEN 0.1 AND 0.5
GROUP BY 
    n.n_name, r.r_name, s.s_acctbal
ORDER BY 
    total_orders_value DESC, nation_name ASC;
