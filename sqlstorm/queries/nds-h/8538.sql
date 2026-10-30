
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank,
           ps.ps_partkey
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
SupplierSummary AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available, 
           AVG(s.s_acctbal) AS avg_supplier_balance
    FROM partsupp ps
    JOIN RankedSuppliers s ON ps.ps_partkey = s.ps_partkey
    WHERE s.supplier_rank <= 5
    GROUP BY ps.ps_partkey
)
SELECT p.p_name, p.p_mfgr, p.p_brand, p.p_type, 
       ss.total_available, ss.avg_supplier_balance
FROM part p
JOIN SupplierSummary ss ON p.p_partkey = ss.ps_partkey
WHERE p.p_retailprice > (
    SELECT AVG(p2.p_retailprice) FROM part p2
) 
ORDER BY ss.total_available DESC, ss.avg_supplier_balance DESC
LIMIT 10;
