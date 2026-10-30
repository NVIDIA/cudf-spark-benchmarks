
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal >= (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
NationsWithComments AS (
    SELECT n.n_nationkey, n.n_name, 
           COALESCE(n.n_comment, 'No Comment') AS comment
    FROM nation n
    WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'Eu%')
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderstatus, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
    HAVING SUM(li.l_extendedprice * (1 - li.l_discount)) > 1000
)
SELECT ns.n_name, COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name, HVC.c_custkey, HVC.c_name,
       od.total_revenue, od.revenue_rank
FROM NationsWithComments ns
LEFT JOIN RankedSuppliers s ON ns.n_nationkey = s.s_nationkey AND s.rn = 1
FULL OUTER JOIN HighValueCustomers HVC ON HVC.c_custkey = (
    SELECT c.c_custkey 
    FROM HighValueCustomers c 
    WHERE c.c_acctbal BETWEEN 1000 AND 5000 
    ORDER BY c.c_acctbal DESC 
    LIMIT 1
)
JOIN OrderDetails od ON od.o_orderkey = (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_orderkey % 2 = 0 
    ORDER BY o.o_orderdate ASC 
    LIMIT 1
)
WHERE ns.n_name IS NOT NULL
ORDER BY od.total_revenue DESC, HVC.c_acctbal ASC NULLS LAST;
