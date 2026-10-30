WITH TopNations AS (
    SELECT n.n_name, SUM(s.s_acctbal) AS total_acct_balance
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
    ORDER BY total_acct_balance DESC
    LIMIT 5
), PartAveragePrice AS (
    SELECT p.p_type, AVG(p.p_retailprice) AS avg_price
    FROM part p
    GROUP BY p.p_type
), CustomerOrderSummary AS (
    SELECT c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_name
    HAVING COUNT(o.o_orderkey) > 2
), LineItemStats AS (
    SELECT l.l_partkey, COUNT(*) AS order_count, SUM(l.l_extendedprice) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_partkey
    HAVING SUM(l.l_extendedprice) > 1000
)
SELECT tn.n_name, 
       ta.avg_price, 
       cus.c_name, 
       cus.order_count, 
       cus.total_spent, 
       lis.order_count AS part_order_count, 
       lis.total_revenue
FROM TopNations tn
JOIN PartAveragePrice ta ON ta.avg_price > 50
JOIN CustomerOrderSummary cus ON tn.total_acct_balance > 50000
JOIN LineItemStats lis ON tn.n_name LIKE CONCAT('%', lis.l_partkey, '%')
ORDER BY tn.total_acct_balance DESC, cus.total_spent DESC;
