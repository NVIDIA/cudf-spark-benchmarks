
WITH SupplierInfo AS (
  SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_availqty) AS total_available_quantity, SUM(ps.ps_supplycost) AS total_supply_cost
  FROM supplier s
  JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
  GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerInfo AS (
  SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
  FROM customer c
  JOIN orders o ON c.c_custkey = o.o_custkey
  GROUP BY c.c_custkey, c.c_name
),
OrderLineInfo AS (
  SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_amount
  FROM lineitem l
  GROUP BY l.l_orderkey
)
SELECT 
  si.s_name AS supplier_name,
  n.n_name AS nation_name,
  ci.c_name AS customer_name,
  ci.total_spent AS customer_spending,
  si.total_available_quantity AS supplier_availability,
  OLI.total_line_amount AS order_line_total
FROM SupplierInfo si
JOIN nation n ON si.s_nationkey = n.n_nationkey
JOIN CustomerInfo ci ON ci.total_spent > 1000
JOIN orders o ON o.o_custkey = ci.c_custkey
JOIN OrderLineInfo OLI ON OLI.l_orderkey = o.o_orderkey
WHERE si.total_supply_cost < 20000
ORDER BY customer_spending DESC, supplier_availability DESC;
