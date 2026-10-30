WITH Ranked_Suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) as rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name IN (SELECT n_name FROM nation WHERE n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name = 'AMERICA'))
),
Top_Suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM Ranked_Suppliers s
    WHERE s.rn <= 5
),
Order_Summary AS (
    SELECT o.o_orderkey, o.o_totalprice, COUNT(DISTINCT l.l_orderkey) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate <= '1997-12-31'
    GROUP BY o.o_orderkey, o.o_totalprice
),
Supplier_Order AS (
    SELECT ts.s_suppkey, os.o_orderkey, os.o_totalprice, os.item_count
    FROM Top_Suppliers ts
    JOIN partsupp ps ON ts.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN Order_Summary os ON l.l_orderkey = os.o_orderkey
)
SELECT ts.s_name, COUNT(DISTINCT so.o_orderkey) AS total_orders, SUM(so.o_totalprice) AS total_value, AVG(so.item_count) AS avg_items_per_order
FROM Supplier_Order so
JOIN Top_Suppliers ts ON so.s_suppkey = ts.s_suppkey
GROUP BY ts.s_name
ORDER BY total_value DESC;