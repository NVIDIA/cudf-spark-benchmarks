WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
), OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY o.o_orderkey, o.o_custkey
), NationRevenue AS (
    SELECT n.n_nationkey, n.n_name, SUM(os.total_revenue) AS total_revenue
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN OrderSummary os ON c.c_custkey = os.o_custkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT r.r_name, COALESCE(SUM(sr.total_cost), 0) AS supplier_cost, COALESCE(SUM(nr.total_revenue), 0) AS nation_revenue
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierInfo sr ON n.n_nationkey = sr.s_nationkey
LEFT JOIN NationRevenue nr ON n.n_nationkey = nr.n_nationkey
GROUP BY r.r_name
ORDER BY r.r_name;