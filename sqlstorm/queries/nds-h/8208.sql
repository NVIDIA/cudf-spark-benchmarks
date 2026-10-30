WITH SupplierAggregates AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name,
           SUM(ps.ps_availqty) AS total_available,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > 1000.00
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
OrderAggregates AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_mktsegment = 'BUILDING'
    GROUP BY c.c_custkey, c.c_name
)
SELECT sa.nation_name, 
       COUNT(DISTINCT sa.s_suppkey) AS supplier_count,
       SUM(sa.total_available) AS overall_available,
       SUM(sa.total_cost) AS overall_cost,
       oa.total_spent, 
       oa.total_orders
FROM SupplierAggregates sa
JOIN OrderAggregates oa ON sa.total_available > 500
GROUP BY sa.nation_name, oa.total_spent, oa.total_orders
ORDER BY overall_cost DESC, overall_available DESC;
