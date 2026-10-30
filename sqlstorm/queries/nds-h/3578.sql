WITH SupplierTotal AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT o.o_orderkey, 
           o.o_custkey, 
           COUNT(l.l_orderkey) AS line_count, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
NationRegion AS (
    SELECT n.n_nationkey, 
           n.n_name, 
           r.r_name,
           ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY n.n_nationkey) AS rn
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT sr.r_name, 
       sr.n_name,
       st.s_name,
       ot.line_count,
       ot.total_line_price,
       COALESCE(st.total_supply_cost, 0) AS supply_cost,
       CASE 
           WHEN ot.total_line_price > 10000 THEN 'High Value'
           WHEN ot.total_line_price BETWEEN 5000 AND 10000 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS order_value_category
FROM NationRegion sr
LEFT JOIN SupplierTotal st ON sr.rn = st.s_suppkey
LEFT JOIN OrderSummary ot ON sr.n_nationkey = ot.o_custkey
WHERE st.total_supply_cost IS NOT NULL
ORDER BY sr.r_name, ot.total_line_price DESC
LIMIT 50;
