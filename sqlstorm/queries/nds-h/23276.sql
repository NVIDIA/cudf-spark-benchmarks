
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER(PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
), 
OrderStats AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate
), 
CustomerNation AS (
    SELECT c.c_custkey, c.c_name, n.n_name, 
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    INNER JOIN nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, n.n_name
    HAVING COUNT(DISTINCT o.o_orderkey) > 1
)
SELECT 
    p.p_name,
    p.p_mfgr,
    COALESCE(rn.s_name, 'Unknown Supplier') AS supplier_name,
    cn.n_name AS customer_nation,
    os.o_orderkey,
    os.o_totalprice,
    os.total_returned,
    CASE 
        WHEN os.o_totalprice IS NULL THEN 'No Sales'
        WHEN os.total_returned > 0 THEN 'Returned'
        ELSE 'Sold'
    END AS sale_status
FROM part p
FULL OUTER JOIN RankedSuppliers rn ON rn.rn = 1 AND p.p_partkey IN (
    SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0
)
LEFT JOIN OrderStats os ON os.o_totalprice = (SELECT MAX(o_totalprice) FROM OrderStats) AND p.p_partkey IN (
    SELECT l.l_partkey FROM lineitem l WHERE l.l_returnflag = 'N' OR l.l_returnflag IS NULL
)
INNER JOIN CustomerNation cn ON cn.order_count = (SELECT MAX(order_count) FROM CustomerNation)
WHERE p.p_size BETWEEN 1 AND 100
ORDER BY p.p_partkey, sale_status DESC NULLS LAST
LIMIT 10 OFFSET 5;
