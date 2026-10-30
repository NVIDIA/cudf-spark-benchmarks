WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100)
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        CONCAT(s.s_name, ' - ', s.s_address) AS supplier_info
    FROM supplier s
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_mktsegment
),
LineItemAggregation AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_partkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_mfgr,
    sd.supplier_info,
    co.total_spent,
    la.total_quantity,
    la.total_revenue,
    rp.p_comment
FROM RankedParts rp
JOIN SupplierDetails sd ON rp.p_partkey = sd.s_suppkey
JOIN CustomerOrders co ON sd.s_nationkey = co.c_custkey
JOIN LineItemAggregation la ON rp.p_partkey = la.l_partkey
WHERE rp.rn <= 5
ORDER BY rp.p_retailprice DESC, co.total_spent DESC;
