
WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
RegionStats AS (
    SELECT r.r_regionkey, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey
),
OrderSummary AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_shipdate >= DATE '1997-01-01'
    GROUP BY o.o_custkey
),
RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, os.total_spent, RANK() OVER (ORDER BY os.total_spent DESC) AS spend_rank
    FROM customer c
    JOIN OrderSummary os ON c.c_custkey = os.o_custkey
),
ExpenseSummary AS (
    SELECT sd.nation_name, SUM(rc.total_spent) AS country_total_spent,
           COUNT(DISTINCT rc.c_custkey) AS unique_customers
    FROM RankedCustomers rc
    JOIN SupplierDetails sd ON rc.c_custkey = sd.s_suppkey
    GROUP BY sd.nation_name
    HAVING SUM(rc.total_spent) > 10000
)
SELECT r.r_name, COALESCE(es.country_total_spent, 0) AS total_spent,
       COALESCE(es.unique_customers, 0) AS unique_customers,
       rns.nation_count
FROM region r
LEFT JOIN RegionStats rns ON r.r_regionkey = rns.r_regionkey
LEFT JOIN ExpenseSummary es ON r.r_name = es.nation_name
ORDER BY total_spent DESC, unique_customers DESC;
