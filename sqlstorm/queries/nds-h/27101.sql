
WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        LENGTH(p.p_name) > 10
),
suppliers_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.s_acctbal > 5000
)
SELECT 
    rp.p_name,
    rp.p_retailprice,
    si.s_name,
    si.region_name,
    CONCAT('Supplier: ', si.s_name, ', Part: ', rp.p_name, ', Price: ', rp.p_retailprice) AS detailed_info
FROM 
    ranked_parts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    suppliers_info si ON ps.ps_suppkey = si.s_suppkey
WHERE 
    rp.rn <= 5
GROUP BY 
    rp.p_name, rp.p_retailprice, si.s_name, si.region_name
ORDER BY 
    rp.p_retailprice DESC, si.region_name;
