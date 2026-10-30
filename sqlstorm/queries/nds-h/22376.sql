
WITH ranked_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= (DATE '1998-10-01' - INTERVAL '1 YEAR')
),
customer_balance AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           CASE 
               WHEN c.c_acctbal > 5000 THEN 'High'
               WHEN c.c_acctbal BETWEEN 1000 AND 5000 THEN 'Medium'
               ELSE 'Low' 
           END AS balance_category
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
supplier_avg_cost AS (
    SELECT ps.ps_suppkey, AVG(ps.ps_supplycost) AS avg_cost
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
),
part_details AS (
    SELECT p.p_partkey, p.p_name, p.p_brand,
           COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
           COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
           MAX(CASE WHEN l.l_returnflag = 'R' THEN 'Returned' ELSE 'Not Returned' END) AS return_status
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
)
SELECT DISTINCT 
    cb.c_name, 
    r.r_name, 
    s.s_name, 
    pd.p_name, 
    pd.total_revenue - (pd.total_quantity * COALESCE(ac.avg_cost, 0)) AS profit_margin,
    CASE 
        WHEN pd.total_quantity > 1000 THEN 'Bulk Order' 
        ELSE 'Standard Order' 
    END AS order_type
FROM customer_balance cb
JOIN nation n ON cb.c_custkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN supplier s ON cb.c_custkey = s.s_nationkey
LEFT JOIN part_details pd ON s.s_suppkey = pd.p_partkey
LEFT JOIN supplier_avg_cost ac ON s.s_suppkey = ac.ps_suppkey
WHERE cb.balance_category = 'High'
  AND EXISTS (
      SELECT 1 
      FROM ranked_orders ro 
      WHERE ro.o_orderkey = s.s_suppkey AND ro.order_rank <= 5
  )
  AND (pd.return_status IS NULL OR pd.return_status = 'Not Returned')
ORDER BY profit_margin DESC; 
