WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_price
    FROM 
        part p
), 
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        n.n_name AS supplier_nation,
        n.n_comment AS nation_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
CustomerOrderCounts AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    rp.p_name,
    rp.p_mfgr,
    rp.p_brand,
    rp.p_type,
    si.s_name AS supplier_name,
    si.s_address AS supplier_address,
    si.s_phone AS supplier_phone,
    cc.c_name AS customer_name,
    cc.order_count,
    rp.p_retailprice,
    CASE 
        WHEN rp.rank_price <= 3 THEN 'Top Price' 
        ELSE 'Standard Price' 
    END AS price_category
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
JOIN 
    CustomerOrderCounts cc ON si.s_suppkey = cc.c_custkey
WHERE 
    rp.p_comment LIKE '%special%'
    AND si.nation_comment LIKE '%prime%'
ORDER BY 
    rp.p_brand, rp.p_retailprice DESC;
