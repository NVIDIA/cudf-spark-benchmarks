SELECT 
    n.n_name AS nation_name, 
    r.r_name AS region_name, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUM(s.s_acctbal) AS total_supplier_balance
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
WHERE 
    o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01' 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' 
GROUP BY 
    n.n_name, r.r_name 
ORDER BY 
    total_revenue DESC, total_orders DESC
LIMIT 10;