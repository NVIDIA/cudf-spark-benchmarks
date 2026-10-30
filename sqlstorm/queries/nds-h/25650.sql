
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
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        n.n_name AS supplier_nation
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
OrderItemDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS line_item_count,
        o.o_orderpriority
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderpriority
),
FinalReport AS (
    SELECT 
        rp.p_name,
        sd.s_name,
        sd.s_address,
        oi.o_orderpriority AS order_priority,
        oi.total_revenue,
        oi.line_item_count
    FROM RankedParts rp
    JOIN partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
    JOIN OrderItemDetails oi ON oi.line_item_count > 5
    WHERE rp.brand_rank <= 3
)
SELECT * 
FROM FinalReport
ORDER BY total_revenue DESC, line_item_count DESC
LIMIT 10;
