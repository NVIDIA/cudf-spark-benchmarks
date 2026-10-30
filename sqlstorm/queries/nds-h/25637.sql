
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_price,
        LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
    WHERE 
        p.p_retailprice > (
            SELECT AVG(p_retailprice) FROM part
        )
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        CONCAT(s.s_name, ' (', s.s_phone, ')') AS supplier_info
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 5
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_type,
    rp.p_retailprice,
    sp.supplier_info,
    co.total_orders,
    rp.comment_length
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sp ON ps.ps_suppkey = sp.s_suppkey
JOIN 
    CustomerOrders co ON sp.s_nationkey = co.c_custkey
WHERE 
    rp.rank_price <= 10
ORDER BY 
    rp.p_retailprice DESC, rp.p_name;
