WITH  OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate) AS order_rank
    FROM orders
    WHERE o_orderstatus = 'O'
),
SupplierPartPrices AS (
    SELECT ps_partkey, ps_suppkey, ps_availqty, ps_supplycost,
           p.p_brand, p.p_name
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps_supplycost < (
        SELECT AVG(ps_supplycost)
        FROM partsupp
    )
),
NationSupplierCount AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT oh.o_orderkey, oh.o_orderdate,
       CASE WHEN sp.ps_supplycost IS NULL THEN 'No Supplier' ELSE sp.p_name END AS part_name,
       sp.ps_supplycost AS supplycost, nsc.n_name AS nation_name,
       tc.total_spent AS customer_spent, tc.c_name AS customer_name
FROM OrderHierarchy oh
LEFT JOIN SupplierPartPrices sp ON oh.o_orderkey = sp.ps_partkey
JOIN NationSupplierCount nsc ON sp.p_brand IS NOT NULL
LEFT JOIN TopCustomers tc ON oh.o_custkey = tc.c_custkey
WHERE (sp.ps_supplycost IS NOT NULL OR tc.total_spent IS NULL)
  AND (DATE_PART('year', oh.o_orderdate) = 1997 OR oh.o_orderdate IS NULL)
ORDER BY oh.o_orderdate DESC, tc.total_spent DESC
LIMIT 100;