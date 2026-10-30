
WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
),
UnsuppliedSubquery AS (
    SELECT 
        DISTINCT ps.ps_partkey 
    FROM partsupp ps
    WHERE ps.ps_availqty = 0
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal,
        COUNT(o.o_orderkey) OVER (PARTITION BY c.c_custkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_mktsegment = c.c_mktsegment)
),
RegionNation AS (
    SELECT r.r_regionkey, n.n_nationkey, n.n_name
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    WHERE r.r_name LIKE 'e%'
),
FinalSelection AS (
    SELECT 
        fp.c_custkey,
        fp.c_name,
        SUM(rp.p_retailprice) AS total_spent
    FROM FilteredCustomers fp
    INNER JOIN RankedParts rp ON fp.order_count > 0 AND rp.rank = 1
    LEFT JOIN UnsuppliedSubquery us ON rp.p_partkey = us.ps_partkey
    WHERE us.ps_partkey IS NULL
    GROUP BY fp.c_custkey, fp.c_name
)
SELECT 
    fn.c_custkey,
    fn.c_name,
    fn.total_spent,
    rn.r_regionkey
FROM FinalSelection fn
LEFT JOIN RegionNation rn ON rn.n_nationkey IN (SELECT DISTINCT c.c_nationkey FROM customer c WHERE c.c_custkey = fn.c_custkey)
WHERE fn.total_spent > 1000 
  AND (fn.c_custkey % 2 = 0 OR fn.c_name LIKE 'A%')
ORDER BY fn.total_spent DESC, fn.c_name
LIMIT 10;
