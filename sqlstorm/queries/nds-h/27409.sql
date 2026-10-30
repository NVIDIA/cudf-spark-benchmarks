
SELECT 
    p.p_name, 
    s.s_name AS supplier_name, 
    CONCAT('Region: ', r.r_name, ', Nation: ', n.n_name) AS location,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    AVG(s.s_acctbal) AS avg_supplier_acct_balance
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem li ON ps.ps_partkey = li.l_partkey
JOIN 
    orders o ON li.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_comment LIKE '%green%'
    AND s.s_comment NOT LIKE '%bad%'
    AND o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
GROUP BY 
    p.p_name, s.s_name, r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5 
ORDER BY 
    total_revenue DESC, avg_supplier_acct_balance DESC;
