
WITH NationSupplierCount AS (
    SELECT n.n_name, COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
AveragePriceByPart AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           COALESCE(avg.avg_supplycost, 0) AS avg_supplycost
    FROM part p
    LEFT JOIN AveragePriceByPart avg ON p.p_partkey = avg.ps_partkey
),
CustomerOrderInfo AS (
    SELECT c.c_custkey, c.c_name, 
           SUM(o.o_totalprice) AS total_spent,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT DISTINCT ns.n_name, 
       pd.p_name, 
       pd.p_retailprice, 
       pd.avg_supplycost, 
       coi.c_name, 
       coi.total_spent
FROM NationSupplierCount ns
JOIN supplier s ON ns.supplier_count > 0 AND ns.n_name IN (
    SELECT DISTINCT n.n_name 
    FROM nation n 
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
)
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN PartDetails pd ON ps.ps_partkey = pd.p_partkey
LEFT JOIN CustomerOrderInfo coi ON pd.p_partkey IN (
    SELECT l.l_partkey 
    FROM lineitem l 
    WHERE l.l_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_orderstatus = 'O'
    )
)
WHERE pd.avg_supplycost > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size IS NOT NULL)
ORDER BY ns.n_name, pd.p_name;
