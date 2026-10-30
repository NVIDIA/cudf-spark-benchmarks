WITH TotalSupplierCost AS (
    SELECT ps.ps_suppkey,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
),
OrderSummary AS (
    SELECT o.o_orderkey,
           o.o_custkey,
           o.o_orderstatus,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           COUNT(l.l_orderkey) AS line_item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderstatus
),
HighValueOrders AS (
    SELECT os.o_orderkey,
           os.o_custkey,
           os.total_price,
           os.line_item_count,
           ROW_NUMBER() OVER (PARTITION BY os.o_custkey ORDER BY os.total_price DESC) AS rn
    FROM OrderSummary os
    WHERE os.total_price > 1000
)
SELECT n.n_name,
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       SUM(t.total_cost) AS total_supplier_cost,
       AVG(hv.total_price) AS avg_high_value_order
FROM nation n
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN HighValueOrders hv ON c.c_custkey = hv.o_custkey
LEFT JOIN TotalSupplierCost t ON t.ps_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_type LIKE '%metal%'
    ORDER BY ps.ps_supplycost DESC
    LIMIT 1
)
WHERE n.n_name IS NOT NULL
GROUP BY n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
ORDER BY customer_count DESC;
