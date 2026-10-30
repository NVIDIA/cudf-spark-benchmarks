SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    AVG(c.c_acctbal) AS average_customer_balance,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COUNT(DISTINCT l.l_orderkey) AS total_line_items,
    MAX(o.o_totalprice) AS max_order_price
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
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
    r.r_name = 'ASIA'
    AND o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND l.l_returnflag = 'N'
GROUP BY 
    r.r_name, n.n_name, s.s_name
ORDER BY 
    total_supply_cost DESC, average_customer_balance ASC;