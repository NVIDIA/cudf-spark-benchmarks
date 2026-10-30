SELECT 
    count(DISTINCT c.c_custkey) AS customer_count,
    sum(o.o_totalprice) AS total_revenue,
    avg(l.l_extendedprice) AS avg_extended_price,
    max(p.p_retailprice) AS max_part_price,
    min(s.s_acctbal) AS min_supplier_balance
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY 
    c.c_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
