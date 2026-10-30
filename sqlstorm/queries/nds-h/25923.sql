
SELECT 
    p.p_mfgr AS manufacturer,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(CASE WHEN LENGTH(p.p_name) > 20 THEN 1 ELSE 0 END) AS long_parts,
    AVG(p.p_retailprice) AS average_price,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    c.c_mktsegment AS market_segment,
    SUM(CASE 
        WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice * (1 - l.l_discount) 
        ELSE 0 
    END) AS total_filled_orders
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
GROUP BY 
    p.p_mfgr, r.r_name, n.n_name, c.c_mktsegment, p.p_name, p.p_retailprice
ORDER BY 
    supplier_count DESC, average_price DESC
LIMIT 100;
