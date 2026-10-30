
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(s.s_acctbal) AS avg_acctbal,
        MAX(s.s_acctbal) AS max_acctbal
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.total_avail_qty,
        ss.avg_acctbal,
        ss.max_acctbal
    FROM SupplierStats ss
    WHERE ss.avg_acctbal > (SELECT AVG(avg_acctbal) FROM SupplierStats)
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    ts.total_avail_qty,
    ts.avg_acctbal
FROM RankedParts rp
LEFT JOIN TopSuppliers ts ON rp.p_partkey = ts.s_suppkey
WHERE rp.price_rank <= 10
   AND (ts.avg_acctbal IS NOT NULL OR rp.p_name LIKE '%ABC%')
   AND (EXISTS (SELECT 1 FROM lineitem l 
                 WHERE l.l_partkey = rp.p_partkey 
                   AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31') 
           OR ts.total_avail_qty IS NULL)
ORDER BY rp.p_brand, rp.p_retailprice DESC
LIMIT 100;
