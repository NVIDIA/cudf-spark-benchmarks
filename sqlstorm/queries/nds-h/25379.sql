
SELECT 
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Nation: ', n.n_name) AS combined_info,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(s.s_acctbal) AS average_supplier_account_balance,
    n.n_name AS region_summary
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
WHERE 
    l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
    AND l.l_returnflag = 'N'
GROUP BY 
    ROLLUP(s.s_name, p.p_name, n.n_name)
ORDER BY 
    total_revenue DESC,
    unique_customers DESC;
