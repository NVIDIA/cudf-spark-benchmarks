SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey,
    l.l_quantity,
    l.l_extendedprice,
    CASE 
        WHEN l.l_discount > 0 THEN 'Discounted' 
        ELSE 'Regular' 
    END AS order_type,
    CONCAT(r.r_name, ' - ', n.n_name) AS region_nation,
    SUBSTR(p.p_comment, 1, 15) AS brief_comment
FROM 
    part AS p
JOIN 
    partsupp AS ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier AS s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem AS l ON p.p_partkey = l.l_partkey
JOIN 
    orders AS o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer AS c ON o.o_custkey = c.c_custkey
JOIN 
    nation AS n ON s.s_nationkey = n.n_nationkey
JOIN 
    region AS r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > 50 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND s.s_acctbal > 1000
ORDER BY 
    order_type DESC, 
    l.l_extendedprice DESC
LIMIT 100;