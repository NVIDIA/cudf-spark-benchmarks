
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), 
OrdersWithDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_linenumber) AS lineitem_count,
           SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
), 
CustomerRank AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           DENSE_RANK() OVER (ORDER BY c.c_acctbal DESC) AS cust_rank
    FROM customer c
)
SELECT r.r_regionkey, r.r_name, COALESCE(SUM(o.total_revenue), 0) AS total_revenue,
       COALESCE(SUM(s.s_acctbal), 0) AS total_supplier_acctbal,
       COUNT(DISTINCT c.c_custkey) AS total_customers,
       MAX(c.c_acctbal) AS max_customer_acctbal
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN RankedSuppliers s ON s.rn <= 3
LEFT JOIN OrdersWithDetails o ON o.o_orderkey IN (
    SELECT o2.o_orderkey
    FROM OrdersWithDetails o2
    WHERE o2.total_revenue > (
        SELECT AVG(total_revenue) FROM OrdersWithDetails
    )
)
LEFT JOIN customer c ON c.c_custkey IN (
    SELECT c2.c_custkey
    FROM CustomerRank c2
    WHERE c2.cust_rank <= 10
)
WHERE n.n_nationkey IS NOT NULL OR r.r_name LIKE '%East%'
GROUP BY r.r_regionkey, r.r_name
HAVING COUNT(DISTINCT s.s_suppkey) > 1 OR SUM(o.total_revenue) > 10000
ORDER BY r.r_regionkey;
