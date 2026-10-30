SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_part_name,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
    MAX(ps.ps_supplycost) AS highest_supply_cost,
    MIN(ps.ps_availqty) AS lowest_avail_qty,
    r.r_name AS region_name,
    SUM(CASE WHEN o.o_orderstatus = 'O' THEN 1 ELSE 0 END) AS open_orders,
    AVG(c.c_acctbal) AS average_account_balance
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
    p.p_comment LIKE '%special%' 
    AND r.r_name IN ('ASIA', 'EUROPE')
GROUP BY 
    r.r_name, SUBSTRING(p.p_name, 1, 10)
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    region_name, short_part_name;
