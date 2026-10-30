WITH SupplyCostCTE AS (
    SELECT ps_partkey, ps_suppkey, 
           ps_availqty,
           ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost DESC) AS rnk
    FROM partsupp
),
AvgCustomerBalance AS (
    SELECT c_nationkey, AVG(c_acctbal) AS avg_balance
    FROM customer
    GROUP BY c_nationkey
),
NationStats AS (
    SELECT n.n_nationkey, n.n_name, 
           COALESCE(SUM(CASE WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice ELSE 0 END), 0) AS total_sales,
           COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END), 0) AS total_returns
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT n.n_name, 
       n.total_sales, 
       n.total_returns, 
       AVG(cb.avg_balance) AS avg_cust_balance,
       CASE 
           WHEN n.total_sales > 100000 THEN 'High sales'
           WHEN n.total_sales BETWEEN 50000 AND 100000 THEN 'Medium sales'
           ELSE 'Low sales' 
       END AS sales_category,
       SUM(CASE WHEN rnk = 1 THEN ps_supplycost END) AS highest_supplycost
FROM NationStats n
JOIN AvgCustomerBalance cb ON n.n_nationkey = cb.c_nationkey
JOIN SupplyCostCTE ps ON n.n_nationkey = ps.ps_suppkey
WHERE n.total_sales IS NOT NULL 
GROUP BY n.n_name, n.total_sales, n.total_returns
HAVING SUM(n.total_sales) > 0
ORDER BY total_sales DESC
LIMIT 10;
