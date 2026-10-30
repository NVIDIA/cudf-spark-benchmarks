
WITH RankedParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
), SupplierStats AS (
    SELECT s.s_nationkey, 
           AVG(s.s_acctbal) AS avg_acctbal, 
           SUM(CASE WHEN s.s_acctbal IS NULL THEN 1 ELSE 0 END) AS null_count
    FROM supplier s
    GROUP BY s.s_nationkey
), HighValueOrders AS (
    SELECT o.o_orderkey, 
           o.o_custkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
), CustomerDetails AS (
    SELECT c.c_custkey, 
           c.c_name, 
           COALESCE(s.avg_acctbal, 0) AS supplier_avg_acctbal
    FROM customer c
    LEFT JOIN SupplierStats s ON c.c_nationkey = s.s_nationkey
), NationPart AS (
    SELECT n.n_nationkey, 
           n.n_name, 
           rp.p_partkey, 
           rp.p_name, 
           rp.p_retailprice
    FROM nation n
    JOIN RankedParts rp ON n.n_nationkey = rp.p_partkey
)
SELECT c.c_name, 
       np.n_name AS nation_name, 
       np.p_name AS part_name, 
       np.p_retailprice, 
       (CASE WHEN c.supplier_avg_acctbal > 0 THEN 'Active' ELSE 'Inactive' END) AS customer_status,
       (SELECT COUNT(DISTINCT hvo.o_orderkey)
        FROM HighValueOrders hvo
        WHERE hvo.o_custkey = c.c_custkey) AS high_value_order_count
FROM CustomerDetails c
JOIN NationPart np ON c.c_custkey = np.p_partkey
LEFT JOIN lineitem l ON np.p_partkey = l.l_partkey
WHERE np.p_retailprice < (SELECT AVG(p2.p_retailprice) FROM part p2)
  AND (c.supplier_avg_acctbal IS NOT NULL OR c.supplier_avg_acctbal IS NULL)
ORDER BY c.c_name, np.p_retailprice DESC
LIMIT 10;
