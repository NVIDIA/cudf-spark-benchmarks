SELECT 
    p_brand, 
    p_type, 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue 
FROM 
    part 
JOIN 
    lineitem ON part.p_partkey = lineitem.l_partkey 
JOIN 
    supplier ON lineitem.l_suppkey = supplier.s_suppkey 
JOIN 
    nation ON supplier.s_nationkey = nation.n_nationkey 
JOIN 
    region ON nation.n_regionkey = region.r_regionkey 
WHERE 
    region.r_name = 'ASIA' 
    AND l_shipdate >= '1997-01-01' 
    AND l_shipdate < '1997-12-31' 
GROUP BY 
    p_brand, 
    p_type 
ORDER BY 
    revenue DESC;