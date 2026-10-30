WITH SupplierCost AS (
    SELECT ps_suppkey,
           SUM(ps_supplycost * ps_availqty) AS total_supplycost,
           COUNT(DISTINCT ps_partkey) AS parts_supplied
    FROM partsupp
    GROUP BY ps_suppkey
),
HighValueSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           sc.total_supplycost,
           sc.parts_supplied,
           ROW_NUMBER() OVER (ORDER BY sc.total_supplycost DESC) AS rn
    FROM supplier s
    JOIN SupplierCost sc ON s.s_suppkey = sc.ps_suppkey
    WHERE s.s_acctbal > 1000
),
OrderSummary AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
           COUNT(l.l_orderkey) AS total_items,
           RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT hs.s_name,
       hs.total_supplycost,
       os.total_value,
       os.total_items,
       CASE 
           WHEN os.total_value IS NULL THEN 'No Orders'
           ELSE 'Orders Placed'
       END AS order_status
FROM HighValueSuppliers hs
LEFT JOIN OrderSummary os ON hs.rn = os.order_rank
FULL OUTER JOIN nation n ON hs.s_suppkey = n.n_nationkey
WHERE hs.parts_supplied > 5 OR n.n_name IS NULL
ORDER BY hs.total_supplycost DESC, os.total_value DESC;
