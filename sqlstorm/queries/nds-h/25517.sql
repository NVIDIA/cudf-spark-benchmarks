SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_type, 
    COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers, 
    SUM(ps.ps_supplycost) AS total_supply_cost, 
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_extended_price, 
    CONCAT('Supplier Count: ', COUNT(DISTINCT ps.ps_suppkey), ', Avg Extended Price: ', ROUND(AVG(l.l_extendedprice * (1 - l.l_discount)), 2)) AS string_benchmark
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_type LIKE '%brass%' 
    AND o.o_orderdate BETWEEN '1995-01-01' AND '1995-12-31'
GROUP BY 
    p.p_partkey, p.p_name, p.p_type
ORDER BY 
    unique_suppliers DESC, total_supply_cost DESC;
