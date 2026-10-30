SELECT 
    SUBSTR(p_name, 1, 10) AS short_name,
    COUNT(DISTINCT s.s_name) AS supplier_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    MAX(p.p_retailprice) AS max_retail_price,
    MIN(l.l_tax) AS min_tax,
    CONCAT(SUBSTR(r.r_name, 1, 15), ' - ', p.p_type) AS region_type
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
WHERE 
    p.p_size > 10
    AND s.s_acctbal > 1000.00
    AND l.l_shipmode IN ('AIR', 'TRUCK')
GROUP BY 
    short_name,
    region_type
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY 
    avg_supply_cost DESC,
    short_name;
