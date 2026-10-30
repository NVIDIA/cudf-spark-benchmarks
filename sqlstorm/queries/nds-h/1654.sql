WITH SupplierSummary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_avail_qty,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_orderdate
),
NationSummary AS (
    SELECT n.n_name, COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_name
),
RankedOrders AS (
    SELECT od.o_orderkey, od.order_total,
           RANK() OVER (ORDER BY od.order_total DESC) AS order_rank
    FROM OrderDetails od
)

SELECT ns.n_name, ss.s_name,
       COALESCE(SUM(os.order_total), 0) AS total_orders,
       COALESCE(MAX(ss.total_avail_qty), 0) AS max_avail_qty,
       CASE 
           WHEN COUNT(os.order_total) > 0 THEN AVG(os.order_total) 
           ELSE NULL 
       END AS avg_order_value
FROM NationSummary ns
LEFT JOIN (
    SELECT DISTINCT od.o_orderkey, od.order_total
    FROM RankedOrders od
    WHERE od.order_rank <= 10
) os ON ns.customer_count > 5
LEFT JOIN SupplierSummary ss ON ns.n_name LIKE CONCAT('%', ss.s_name, '%')
GROUP BY ns.n_name, ss.s_name
ORDER BY ns.n_name, ss.s_name;
