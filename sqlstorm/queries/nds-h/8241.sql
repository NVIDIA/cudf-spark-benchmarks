WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE c.c_acctbal > 1000
),
TopProducts AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    JOIN RankedOrders ro ON l.l_orderkey = ro.o_orderkey
    GROUP BY l.l_orderkey
),
ProductSupplier AS (
    SELECT ps.ps_partkey, s.s_name, SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_name
)
SELECT ro.o_orderdate, ro.o_totalprice, tp.total_revenue, ps.s_name, 
       ps.total_supplycost, 
       RANK() OVER (ORDER BY tp.total_revenue DESC) AS revenue_rank
FROM RankedOrders ro
JOIN TopProducts tp ON ro.o_orderkey = tp.l_orderkey
JOIN ProductSupplier ps ON tp.l_orderkey = ps.ps_partkey
WHERE ro.rn <= 5
ORDER BY ro.o_orderdate DESC;
