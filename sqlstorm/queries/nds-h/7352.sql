
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name,
           RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, n.n_name AS nation_name
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE c.c_acctbal > 50000
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
)
SELECT hc.nation_name, 
       SUM(os.total_revenue) AS total_revenue, 
       COUNT(DISTINCT os.o_orderkey) AS order_count, 
       COUNT(DISTINCT r.s_suppkey) AS supplier_count
FROM OrderSummary os
JOIN HighValueCustomers hc ON os.o_custkey = hc.c_custkey
JOIN RankedSuppliers r ON hc.nation_name = r.nation_name AND r.rank <= 5
GROUP BY hc.nation_name
ORDER BY total_revenue DESC;
