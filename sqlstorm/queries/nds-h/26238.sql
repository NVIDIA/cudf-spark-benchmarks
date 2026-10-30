WITH RankedParts AS (
    SELECT 
        p_name,
        p_type,
        p_brand,
        p_retailprice,
        LENGTH(p_comment) AS comment_length,
        ROW_NUMBER() OVER (PARTITION BY p_type ORDER BY p_retailprice DESC) AS rank
    FROM part
    WHERE p_brand LIKE '%A%'
),
SupplierDetails AS (
    SELECT 
        s.s_name,
        s.s_phone,
        s.s_acctbal,
        n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS part_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY o.o_orderkey
),
FinalSelection AS (
    SELECT 
        rp.p_name,
        rp.p_type,
        rp.p_retailprice,
        sd.s_name,
        os.total_revenue,
        os.part_count
    FROM RankedParts rp
    JOIN SupplierDetails sd ON rp.rank <= 5
    JOIN OrderSummary os ON os.part_count > 10
)
SELECT 
    p_name,
    p_type,
    p_retailprice,
    s_name,
    total_revenue
FROM FinalSelection
ORDER BY total_revenue DESC;