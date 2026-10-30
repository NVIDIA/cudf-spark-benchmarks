WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_nationkey,
           SUM(l.l_quantity) AS total_quantity
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_nationkey
),
HighValueOrders AS (
    SELECT os.o_orderkey, os.o_totalprice, os.o_orderdate, os.total_quantity,
           n.n_name
    FROM OrderSummary os
    LEFT JOIN nation n ON os.c_nationkey = n.n_nationkey
    WHERE os.o_totalprice > 1000
)
SELECT hvo.o_orderkey, hvo.o_totalprice, hvo.o_orderdate, hvo.total_quantity,
       COALESCE(r.s_name, 'No Supplier') AS supplier_name, 
       r.s_acctbal AS supplier_acctbal
FROM HighValueOrders hvo
LEFT JOIN RankedSuppliers r ON hvo.o_orderkey = r.s_suppkey
WHERE hvo.o_orderdate >= '1997-01-01'
  AND (hvo.total_quantity IS NULL OR hvo.total_quantity > 5)
ORDER BY hvo.o_orderdate DESC, hvo.o_totalprice ASC
LIMIT 50;