SELECT 
    CONCAT('Supplier: ', s.s_name, ' | Nation: ', n.n_name, ' | Region: ', r.r_name, 
           ' | Part: ', p.p_name, ' | Quantity: ', ps.ps_availqty, 
           ' | Comment: ', p.p_comment) AS Info,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
    COUNT(DISTINCT ps.ps_partkey) AS UniquePartsSupplied
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    r.r_name LIKE 'Asia%' AND 
    p.p_comment LIKE '%fragile%' AND 
    ps.ps_availqty > 0
GROUP BY 
    s.s_name, n.n_name, r.r_name, p.p_name, ps.ps_availqty, p.p_comment
ORDER BY 
    TotalSupplyCost DESC, UniquePartsSupplied DESC
LIMIT 10;
