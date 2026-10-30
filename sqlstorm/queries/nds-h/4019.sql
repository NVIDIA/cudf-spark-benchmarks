WITH region_summary AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count,
           SUM(s.s_acctbal) AS total_supplier_balance
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
),
customer_summary AS (
    SELECT c.c_nationkey, COUNT(DISTINCT c.c_custkey) AS cust_count,
           AVG(c.c_acctbal) AS avg_acct_balance
    FROM customer c
    GROUP BY c.c_nationkey
),
order_summary AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_orders,
           AVG(o.o_totalprice) AS avg_order_value
    FROM orders o
    GROUP BY o.o_custkey
),
lineitem_analysis AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales,
           RANK() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
)
SELECT rs.r_name, 
       cs.cust_count, 
       cs.avg_acct_balance, 
       COALESCE(os.total_orders, 0) AS total_orders, 
       COALESCE(os.avg_order_value, 0) AS avg_order_value, 
       la.net_sales, 
       la.sales_rank
FROM region_summary rs
JOIN customer_summary cs ON rs.r_regionkey = cs.c_nationkey
LEFT JOIN order_summary os ON cs.c_nationkey = os.o_custkey
LEFT JOIN lineitem_analysis la ON os.o_custkey = la.l_orderkey
WHERE rs.total_supplier_balance > 100000
  AND (cs.avg_acct_balance IS NOT NULL OR os.total_orders > 5)
ORDER BY rs.r_name, cs.cust_count DESC;
