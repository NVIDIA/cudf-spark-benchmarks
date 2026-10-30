WITH RankedParts AS (
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
        ROW_NUMBER() OVER(PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as price_rank
    FROM part p
    WHERE LENGTH(p.p_comment) > 10
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        s.s_acctbal,
        SUBSTRING(s.s_comment FROM 1 FOR 30) AS short_comment
    FROM supplier s
    WHERE POSITION('important' IN s.s_comment) > 0
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS lineitem_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_totalprice > 10000
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate
),
FinalResult AS (
    SELECT 
        rp.p_name,
        rp.p_brand,
        rp.p_retailprice,
        sd.s_name AS supplier_name,
        hvo.o_orderkey,
        hvo.o_totalprice
    FROM RankedParts rp
    JOIN partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
    JOIN HighValueOrders hvo ON hvo.o_orderkey = ps.ps_partkey
    WHERE rp.price_rank <= 5
)
SELECT 
    p_name,
    p_brand,
    p_retailprice,
    supplier_name,
    o_orderkey,
    o_totalprice
FROM FinalResult
ORDER BY p_retailprice DESC, supplier_name;
