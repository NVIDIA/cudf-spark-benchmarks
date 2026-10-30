WITH  order_totals AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
supplier_ranks AS (
    SELECT s.s_suppkey, s.s_name, 
           RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank,
           n.n_regionkey
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, n.n_regionkey
),
high_value_orders AS (
    SELECT ot.o_orderkey, ot.total_amount,
           CASE 
               WHEN ot.total_amount > 10000 THEN 'High Value'
               ELSE 'Standard Value' 
           END AS order_value_category
    FROM order_totals ot
),
top_suppliers AS (
    SELECT sr.s_suppkey, sr.s_name, sr.rank
    FROM supplier_ranks sr
    WHERE sr.rank <= 5
)
SELECT o.o_orderkey, 
       c.c_name AS customer_name,
       o.o_orderdate,
       hvo.order_value_category,
       COALESCE(ts.s_name, 'No Supplier') AS top_supplier_name
FROM high_value_orders hvo
LEFT JOIN orders o ON o.o_orderkey = hvo.o_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN top_suppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE o.o_orderstatus = 'O'
  AND hvo.total_amount > 5000
  AND l.l_shipdate <= cast('1998-10-01' as date)
ORDER BY hvo.total_amount DESC, o.o_orderdate DESC;