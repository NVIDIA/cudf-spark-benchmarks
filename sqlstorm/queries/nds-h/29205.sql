SELECT 
    CONCAT(s.s_name, ' from ', n.n_name, ' is manufacturing ', p.p_name, ' which is a ', p.p_type, 
           ' of size ', CAST(p.p_size AS STRING), 
           ' in ', p.p_container, 
           ' container priced at $', CAST(p.p_retailprice AS STRING), 
           ' with remark: "', p.p_comment, '"') AS supplier_part_info
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
ORDER BY 
    p.p_retailprice DESC
LIMIT 10;
