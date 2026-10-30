WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size BETWEEN 10 AND 50
), SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'Unknown'
            WHEN s.s_acctbal < 1000 THEN 'Low Balance'
            ELSE 'Sufficient Balance'
        END AS balance_status
    FROM supplier s
    WHERE s.s_comment NOT LIKE '%unavailable%'
), OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(DISTINCT l.l_linenumber) AS lineitem_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_retailprice,
    COALESCE(sd.s_name, 'No Supplier') AS supplier_name,
    os.net_revenue AS order_revenue,
    os.lineitem_count,
    CASE 
        WHEN os.net_revenue IS NULL THEN 'No Revenue'
        WHEN os.lineitem_count = 0 THEN 'No Line Items'
        ELSE 'Has Revenue'
    END AS revenue_status
FROM RankedParts rp
LEFT JOIN partsupp ps ON rp.p_partkey = ps.ps_partkey
LEFT JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
LEFT JOIN OrderSummary os ON os.o_orderkey = (SELECT MIN(o_orderkey) FROM orders WHERE o_orderstatus = 'F' AND o_totalprice > 5000)
WHERE rp.rn <= 5 AND (sd.balance_status = 'Sufficient Balance' OR sd.s_name IS NULL)
ORDER BY rp.p_retailprice DESC, os.net_revenue DESC
LIMIT 10;
