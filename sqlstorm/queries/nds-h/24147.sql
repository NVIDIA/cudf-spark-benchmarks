WITH RegionPartPrices AS (
    SELECT r.r_name, p.p_partkey, p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY p.p_retailprice DESC) AS rnk
    FROM region r
    JOIN nation n ON n.n_regionkey = r.r_regionkey
    JOIN supplier s ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON p.p_partkey = ps.ps_partkey
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           DENSE_RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus IN ('O', 'F') AND l.l_discount BETWEEN 0.01 AND 0.1
    GROUP BY o.o_orderkey, o.o_custkey
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2) 
      OR c.c_acctbal IS NULL
),
MaxPrices AS (
    SELECT p.p_partkey, MAX(ps.ps_supplycost) AS max_cost
    FROM partsupp ps
    JOIN part p ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
)
SELECT rpp.r_name, fpo.o_orderkey, fpo.total_sales, 
       COALESCE(hvc.c_name, 'UNKNOWN CUSTOMER') AS customer_name,
       CASE 
            WHEN rpp.rnk = 1 THEN 'Most Expensive'
            WHEN rpp.rnk <= 5 THEN 'Top 5 Expensive'
            ELSE 'Other' 
       END AS part_category,
       mps.max_cost - p.p_retailprice AS price_difference 
FROM RegionPartPrices rpp
FULL OUTER JOIN FilteredOrders fpo ON fpo.total_sales > 1000
LEFT JOIN HighValueCustomers hvc ON hvc.c_custkey = fpo.o_custkey
JOIN part p ON p.p_partkey = rpp.p_partkey
JOIN MaxPrices mps ON mps.p_partkey = rpp.p_partkey
WHERE (rpp.r_name LIKE 'N%' OR rpp.r_name IS NULL)
  AND (mps.max_cost < p.p_retailprice OR p.p_comment IS NOT NULL)
ORDER BY rpp.r_name, fpo.total_sales DESC;
