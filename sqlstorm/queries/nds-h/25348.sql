
SELECT 
    p.p_name AS part_name,
    p.p_mfgr AS manufacturer,
    s.s_name AS supplier_name,
    s.s_acctbal AS supplier_account_balance,
    CONCAT('Region: ', r.r_name, ' (', n.n_name, ')') AS supplier_region,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COUNT(DISTINCT c.c_custkey) AS total_customers
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
JOIN 
    customer c ON c.c_custkey = o.o_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size BETWEEN 10 AND 20 AND 
    s.s_acctbal > 5000 AND 
    (l.l_shipmode = 'AIR' OR l.l_shipmode = 'RAIL')
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, s.s_name, s.s_acctbal, r.r_name, n.n_name
HAVING 
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) < 50
ORDER BY 
    total_revenue DESC, total_orders DESC
LIMIT 100;
