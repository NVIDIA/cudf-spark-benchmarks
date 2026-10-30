
SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue, 
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000 THEN 'High Revenue' 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) BETWEEN 500 AND 1000 THEN 'Medium Revenue' 
        ELSE 'Low Revenue' 
    END AS revenue_category,
    CONCAT(s.s_name, ' from ', n.n_name) AS supplier_location,
    RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
JOIN 
    customer c ON o.o_custkey = c.c_custkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
WHERE 
    l.l_shipdate > DATE '1997-01-01' 
    AND n.n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name = 'Europe') 
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    n.n_name 
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 0 
ORDER BY 
    revenue DESC, 
    revenue_rank;
