WITH AvgSupplierCost AS (
    SELECT ps_partkey, AVG(ps_supplycost) AS avg_supplycost
    FROM partsupp
    GROUP BY ps_partkey
),
TopRegions AS (
    SELECT r.r_regionkey, r.r_name, SUM(s.s_acctbal) AS total_acctbal
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
    ORDER BY total_acctbal DESC
    LIMIT 5
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, c.c_mktsegment
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O'
)
SELECT os.o_orderkey, os.o_orderdate, os.o_totalprice, os.c_name, os.c_mktsegment, 
       tr.r_name, avgsc.avg_supplycost
FROM OrderSummary os
JOIN lineitem l ON os.o_orderkey = l.l_orderkey
JOIN AvgSupplierCost avgsc ON l.l_partkey = avgsc.ps_partkey
JOIN TopRegions tr ON os.o_orderkey % 5 = tr.r_regionkey
WHERE os.o_totalprice > (SELECT AVG(o_totalprice) FROM orders) 
  AND avgsc.avg_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY os.o_orderdate DESC, os.o_orderkey ASC;
