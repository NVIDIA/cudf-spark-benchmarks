
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUBSTRING(p.p_comment, 1, 15) AS short_comment,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_price
    FROM 
        part p
    WHERE 
        LENGTH(p.p_comment) > 15
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_phone,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 1000
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.short_comment,
    si.s_name AS supplier_name,
    si.nation_name,
    COUNT(o.o_orderkey) AS total_orders
FROM 
    RankedParts rp
JOIN 
    lineitem l ON rp.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    SupplierInfo si ON si.s_suppkey = l.l_suppkey
WHERE 
    rp.rank_price <= 3
GROUP BY 
    rp.p_partkey, rp.p_name, rp.short_comment, si.s_name, si.nation_name
ORDER BY 
    total_orders DESC, rp.p_name;
