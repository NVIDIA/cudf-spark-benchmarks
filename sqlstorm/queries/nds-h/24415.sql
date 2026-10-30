WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        CASE 
            WHEN s.s_acctbal IS NULL THEN 0 
            ELSE s.s_acctbal 
        END AS adjusted_acctbal
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT od.o_orderkey) AS total_orders,
    SUM(COALESCE(sd.adjusted_acctbal, 0)) AS total_supplier_balance,
    AVG(CASE WHEN rp.rn = 1 THEN rp.p_retailprice END) AS highest_price_per_mfgr
FROM nation n
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN SupplierDetails sd ON n.n_nationkey = sd.s_suppkey
LEFT JOIN FilteredOrders od ON n.n_nationkey = od.o_custkey
LEFT JOIN RankedParts rp ON rp.rn <= 5
GROUP BY n.n_name, r.r_name
HAVING COUNT(DISTINCT od.o_orderkey) > 5 OR SUM(sd.adjusted_acctbal) > 5000
ORDER BY total_orders DESC, region_name, nation_name;
