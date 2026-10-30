WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS part_count,
        COUNT(DISTINCT o.o_custkey) AS customer_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),

SupplierSummary AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_suppkey, s.s_name
),

NationRevenue AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(os.total_revenue) AS revenue
    FROM OrderSummary os
    JOIN customer c ON os.o_orderkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING SUM(os.total_revenue) > 1000000
)

SELECT 
    r.r_name,
    COUNT(DISTINCT nr.n_nationkey) AS nations,
    SUM(nr.revenue) AS total_revenue
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN NationRevenue nr ON n.n_nationkey = nr.n_nationkey
GROUP BY r.r_name
ORDER BY total_revenue DESC
LIMIT 10;
