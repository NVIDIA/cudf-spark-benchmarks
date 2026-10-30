SELECT 
    p_brand, 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue 
FROM 
    part 
JOIN 
    lineitem ON part.p_partkey = lineitem.l_partkey 
JOIN 
    partsupp ON part.p_partkey = partsupp.ps_partkey 
JOIN 
    supplier ON partsupp.ps_suppkey = supplier.s_suppkey 
JOIN 
    nation ON supplier.s_nationkey = nation.n_nationkey 
JOIN 
    region ON nation.n_regionkey = region.r_regionkey 
WHERE 
    region.r_name = 'Asia' 
GROUP BY 
    p_brand 
ORDER BY 
    revenue DESC 
LIMIT 10;
