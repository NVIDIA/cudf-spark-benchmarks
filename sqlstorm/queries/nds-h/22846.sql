
WITH RankedParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_mfgr, 
           p.p_brand, 
           p.p_type, 
           p.p_size, 
           p.p_container, 
           p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
),
SupplierDetails AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_nationkey, 
           s.s_acctbal, 
           COALESCE(s.s_comment, '[No Comment]') AS comment_with_default
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) 
                         FROM supplier s2) 
      OR s.s_comment IS NULL
),
CustomerCount AS (
    SELECT n.n_name, 
           COUNT(DISTINCT c.c_custkey) AS cust_count
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_name
),
MaxOrder AS (
    SELECT o.o_custkey, 
           MAX(o.o_totalprice) AS max_price
    FROM orders o
    GROUP BY o.o_custkey
)
SELECT 
    R.r_name,
    SUM(CASE 
            WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) 
            ELSE 0 
        END) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(s.s_acctbal) OVER (PARTITION BY R.r_regionkey) AS avg_supplier_balance,
    COUNT(DISTINCT CASE WHEN cd.cust_count > 10 THEN cd.n_name END) AS high_customer_count_nations
FROM region R
LEFT JOIN nation n ON R.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN SupplierDetails s ON s.s_suppkey IN (SELECT ps.ps_suppkey 
                                          FROM partsupp ps 
                                          WHERE ps.ps_partkey IN (SELECT rp.p_partkey 
                                                                  FROM RankedParts rp 
                                                                  WHERE rp.rn = 1))
LEFT JOIN CustomerCount cd ON n.n_name = cd.n_name
GROUP BY R.r_name, R.r_regionkey, s.s_acctbal
HAVING COUNT(DISTINCT o.o_orderkey) > 5
    AND SUM(CASE WHEN l.l_discount > 0 THEN 1 ELSE 0 END) > 10
ORDER BY total_revenue DESC NULLS LAST;
