
SELECT 
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Quantity: ', ps.ps_availqty, 
           ', Cost: $', CAST(ps.ps_supplycost AS DECIMAL(10, 2)), ', Region: ', r.r_name) AS benchmark_output
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
WHERE 
    p.p_size BETWEEN 10 AND 50
    AND s.s_acctbal > 10000.00
    AND r.r_name LIKE 'Eu%'
GROUP BY 
    s.s_name, p.p_name, ps.ps_availqty, ps.ps_supplycost, r.r_name
ORDER BY 
    ps.ps_supplycost DESC
LIMIT 100;
