SELECT 
    n.n_name as nation_name,
    sum(l.l_extendedprice * (1 - l.l_discount)) as total_revenue,
    avg(s.s_acctbal) as avg_supplier_balance,
    count(distinct o.o_orderkey) as total_orders
FROM 
    nation n
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
    o.o_orderstatus = 'F' 
    AND l.l_shipdate >= '1997-01-01' 
    AND l.l_shipdate < '1997-12-31'
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC
LIMIT 10;