
SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    p.p_brand,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
    CONCAT(r.r_name, ' - ', n.n_name) AS region_nation,
    MAX(o.o_totalprice) AS max_order_price,
    AVG(CAST(SUBSTRING(s.s_comment, POSITION('quality' IN s.s_comment) + 8, 5) AS DECIMAL(10, 2))) AS average_quality_rating
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
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_comment NOT LIKE '%unused%'
    AND s.s_acctbal > 10000
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1997-01-01'
GROUP BY 
    p.p_name, p.p_brand, r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_supply_value DESC;
