
WITH  Supplier_Ranks AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
Top_Suppliers AS (
    SELECT sr.s_suppkey, sr.s_name, sr.s_acctbal, n.n_name, sr.s_nationkey
    FROM Supplier_Ranks sr
    JOIN nation n ON sr.s_nationkey = n.n_nationkey
    WHERE sr.rank <= 5
),
Order_Summary AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_nationkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_nationkey
),
Country_Revenue AS (
    SELECT n.n_name, SUM(os.total_revenue) AS total_revenue_by_country, c.c_nationkey
    FROM Order_Summary os
    JOIN customer c ON os.c_nationkey = c.c_nationkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE os.total_revenue IS NOT NULL
    GROUP BY n.n_name, c.c_nationkey
),
Final_Report AS (
    SELECT ts.s_name, ts.s_acctbal, cr.total_revenue_by_country
    FROM Top_Suppliers ts
    LEFT JOIN Country_Revenue cr ON ts.s_nationkey = cr.c_nationkey
)
SELECT f.s_name, f.s_acctbal, COALESCE(f.total_revenue_by_country, 0) AS revenue
FROM Final_Report f
WHERE f.s_acctbal > (
    SELECT AVG(s.s_acctbal)
    FROM supplier s
)
ORDER BY revenue DESC
LIMIT 10;
