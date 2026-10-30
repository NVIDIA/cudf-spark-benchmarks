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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_name LIKE '%widget%'
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        SUBSTRING(s.s_comment, 1, 50) AS short_comment
    FROM supplier s
    WHERE s.s_acctbal > 10000
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        COUNT(l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey
)
SELECT 
    rp.p_name,
    rp.p_mfgr,
    rp.price_rank,
    fs.s_name,
    fs.short_comment,
    cos.c_name,
    cos.total_revenue
FROM RankedParts rp
JOIN FilteredSuppliers fs ON fs.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'Germany')
JOIN CustomerOrderSummary cos ON cos.lineitem_count > 5
WHERE rp.price_rank <= 10
ORDER BY total_revenue DESC, rp.p_name;
