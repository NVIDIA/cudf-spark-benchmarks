SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_part_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
    CONCAT(r.r_name, ' - ', n.n_name) AS region_nation,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(c.c_acctbal) AS avg_account_balance
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_retailprice > 100.00 
    AND l.l_quantity < 50 
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    short_part_name, region_nation
ORDER BY 
    total_cost DESC, supplier_count DESC;