WITH RankedOrders AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN DATE '1994-01-01' AND DATE '1995-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
),
TopRevenueOrders AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           ro.total_revenue
    FROM RankedOrders ro
    JOIN orders o ON ro.o_orderkey = o.o_orderkey
    WHERE ro.revenue_rank <= 10
),
SupplierCosts AS (
    SELECT s.s_suppkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
FinalResults AS (
    SELECT tro.o_orderkey, 
           tro.total_revenue, 
           sc.total_supplycost, 
           (tro.total_revenue - sc.total_supplycost) AS profit
    FROM TopRevenueOrders tro
    JOIN SupplierCosts sc ON tro.o_orderkey % 10 = sc.s_suppkey % 10
)
SELECT prof.o_orderkey, 
       prof.total_revenue, 
       prof.total_supplycost, 
       prof.profit
FROM FinalResults prof
WHERE prof.profit > 0 
ORDER BY prof.profit DESC
LIMIT 50;
