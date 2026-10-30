WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           o.o_orderpriority,
           c.c_mktsegment,
           DENSE_RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O'
      AND o.o_orderdate >= DATE '1997-01-01'
),
FilteredLineItems AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    JOIN RankedOrders ro ON l.l_orderkey = ro.o_orderkey
    WHERE ro.order_rank <= 10
    GROUP BY l.l_orderkey
),
FinalReport AS (
    SELECT ro.o_orderkey,
           ro.o_orderdate,
           ro.o_totalprice,
           ro.o_orderpriority,
           ro.c_mktsegment,
           fli.total_revenue
    FROM RankedOrders ro
    JOIN FilteredLineItems fli ON ro.o_orderkey = fli.l_orderkey
)
SELECT fr.o_orderkey,
       fr.o_orderdate,
       fr.o_orderpriority,
       fr.c_mktsegment,
       fr.total_revenue,
       RANK() OVER (PARTITION BY fr.c_mktsegment ORDER BY fr.total_revenue DESC) AS revenue_rank
FROM FinalReport fr
ORDER BY fr.c_mktsegment, revenue_rank;