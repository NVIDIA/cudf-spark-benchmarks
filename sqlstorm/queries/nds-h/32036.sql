WITH  OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderstatus = 'F' AND o.o_orderdate >= '1997-01-01'
),
TopSuppliers AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size > 10 AND p.p_retailprice BETWEEN 100 AND 500
    GROUP BY ps.ps_suppkey
    HAVING SUM(ps.ps_availqty) > 50
),
CustomerRanking AS (
    SELECT c.c_custkey, 
           RANK() OVER (ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM customer c
    WHERE c.c_mktsegment IN ('AUTOMOBILE', 'FURNITURE')
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, r.r_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE s.s_acctbal IS NOT NULL
)
SELECT 
    oh.o_orderkey,
    oh.o_orderdate,
    oh.o_totalprice,
    sr.total_supplycost,
    cr.customer_rank,
    sd.s_name,
    sd.s_acctbal,
    sd.r_name,
    COUNT(l.l_orderkey) AS lineitem_count
FROM OrderHierarchy oh
LEFT JOIN lineitem l ON oh.o_orderkey = l.l_orderkey
JOIN TopSuppliers sr ON l.l_suppkey = sr.ps_suppkey
JOIN CustomerRanking cr ON oh.o_orderkey = cr.c_custkey
JOIN SupplierDetails sd ON l.l_suppkey = sd.s_suppkey
WHERE 
    (oh.o_totalprice IS NOT NULL AND oh.o_totalprice > 5000)
    OR (sd.s_acctbal > 1000 AND sd.r_name IS NOT NULL)
GROUP BY oh.o_orderkey, oh.o_orderdate, oh.o_totalprice, sr.total_supplycost, 
         cr.customer_rank, sd.s_name, sd.s_acctbal, sd.r_name
HAVING COUNT(l.l_orderkey) > 3
ORDER BY oh.o_totalprice DESC, oh.o_orderdate DESC;