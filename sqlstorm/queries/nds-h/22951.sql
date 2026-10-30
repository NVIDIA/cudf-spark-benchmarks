
WITH RecursivePart AS (
    SELECT p_partkey, 
           p_name, 
           p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p_brand ORDER BY p_retailprice DESC) AS rank_price
    FROM part
),
SupplierAggregates AS (
    SELECT s.s_suppkey,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT p.p_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey
),
TopCustomers AS (
    SELECT c.c_custkey, 
           c.c_name, 
           SUM(o.o_totalprice) AS total_spent,
           ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
DiscountedLineItems AS (
    SELECT l.l_orderkey, 
           l.l_partkey, 
           l.l_discount,
           (l.l_extendedprice * (1 - l.l_discount)) AS discounted_price
    FROM lineitem l
    WHERE l.l_discount > 0.1
),
NationSupplierCount AS (
    SELECT n.n_name, 
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT r.r_name,
       COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
       AVG(sa.total_supply_cost) AS avg_supply_cost,
       SUM(td.discounted_price) AS total_discounted_revenue,
       ns.supplier_count 
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN SupplierAggregates sa ON s.s_suppkey = sa.s_suppkey
LEFT JOIN DiscountedLineItems td ON ps.ps_partkey = td.l_partkey
LEFT JOIN NationSupplierCount ns ON n.n_name = ns.n_name
WHERE r.r_name IS NOT NULL
AND (EXISTS (SELECT 1 
              FROM TopCustomers tc 
              WHERE tc.total_spent > 10000) 
      OR (SELECT COUNT(*) FROM orders) > 100)
GROUP BY r.r_name, ns.supplier_count
HAVING COUNT(DISTINCT ps.ps_partkey) > 5
ORDER BY total_discounted_revenue DESC, avg_supply_cost ASC
LIMIT 10 OFFSET 5;
