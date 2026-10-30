SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    p.p_type,
    p.p_size,
    p.p_container,
    p.p_retailprice,
    p.p_comment,
    CONCAT('Supplier: ', s.s_name, ', Region: ', r.r_name) AS supplier_region,
    COALESCE(
        (SELECT SUM(ps.ps_availqty) 
         FROM partsupp ps 
         WHERE ps.ps_partkey = p.p_partkey), 0) AS total_available_quantity,
    CASE 
        WHEN (SELECT COUNT(*) FROM lineitem l WHERE l.l_partkey = p.p_partkey) > 0 
        THEN 'Available for Order' 
        ELSE 'Not Available' 
    END AS availability_status
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
    p.p_retailprice < (SELECT AVG(p2.p_retailprice) FROM part p2)
AND 
    LENGTH(p.p_comment) > 5
ORDER BY 
    p.p_retailprice DESC
LIMIT 100;
