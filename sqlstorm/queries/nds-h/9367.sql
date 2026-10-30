WITH SupplierCost AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-02-01'
    GROUP BY o.o_orderkey
),
CustomerSegment AS (
    SELECT c.c_mktsegment, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_mktsegment
)
SELECT r.r_name AS region,
       n.n_name AS nation,
       COALESCE(SUM(sc.total_supply_cost), 0) AS total_supplier_cost,
       COALESCE(SUM(os.total_price), 0) AS total_order_value,
       CS.c_mktsegment AS market_segment,
       COUNT(DISTINCT CS.order_count) AS distinct_order_count
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierCost sc ON n.n_nationkey = sc.s_suppkey
LEFT JOIN OrderSummary os ON os.total_price IS NOT NULL
LEFT JOIN CustomerSegment CS ON cs.c_mktsegment IS NOT NULL
GROUP BY r.r_name, n.n_name, CS.c_mktsegment
ORDER BY total_supplier_cost DESC, total_order_value DESC;