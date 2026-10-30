WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal < (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey <> sh.s_suppkey
    WHERE s.s_acctbal < sh.s_acctbal
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           ROW_NUMBER() OVER(PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 500.0)
),
CustomerOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
FilteredOrders AS (
    SELECT co.o_orderkey, co.total_spent
    FROM CustomerOrders co
    WHERE co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
)
SELECT 
    ps.ps_partkey,
    pd.p_name,
    SUM(ps.ps_availqty) AS total_available,
    MAX(s.s_acctbal) AS max_supplier_balance,
    COUNT(DISTINCT co.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied
FROM partsupp ps
LEFT JOIN PartDetails pd ON ps.ps_partkey = pd.p_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey AND l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
LEFT JOIN FilteredOrders co ON l.l_orderkey = co.o_orderkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE pd.rn <= 5 OR s.s_acctbal IS NULL
GROUP BY ps.ps_partkey, pd.p_name
HAVING SUM(ps.ps_availqty) > 1000 AND COUNT(DISTINCT r.r_regionkey) < 3
ORDER BY total_available DESC, max_supplier_balance DESC
LIMIT 50 OFFSET 0;