SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    CONCAT('Brand: ', p.p_brand, ', Size: ', p.p_size) AS brand_and_size,
    LEFT(r.r_name, 5) AS region_abbr,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(s.s_acctbal) AS average_account_balance,
    MAX(o.o_totalprice) AS max_order_price
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
    p.p_container LIKE 'SM%'
    AND s.s_comment LIKE '%reliable%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    short_name, brand_and_size, region_abbr
ORDER BY 
    total_available_quantity DESC, max_order_price DESC
LIMIT 100;