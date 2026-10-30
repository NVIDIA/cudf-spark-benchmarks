SELECT 
    n.n_name,
    count(distinct o.o_orderkey) AS total_orders,
    sum(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    avg(s.s_acctbal) AS avg_supplier_balance,
    max(l.l_extendedprice) AS max_lineprice,
    min(l.l_extendedprice) AS min_lineprice
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
    l.l_shipdate >= '1997-01-01' AND l.l_shipdate <= '1997-12-31'
    AND n.n_name IN ('USA', 'CANADA', 'MEXICO')
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC, total_orders DESC
LIMIT 10;