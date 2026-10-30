WITH RankedOrders AS (
    SELECT o.o_orderkey, 
           o.o_orderstatus, 
           o.o_totalprice, 
           o.o_orderdate, 
           o.o_orderpriority, 
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as total_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
HighValueOrders AS (
    SELECT ro.o_orderkey, 
           ro.o_orderstatus, 
           ro.o_totalprice, 
           ro.o_orderdate, 
           ro.o_orderpriority
    FROM RankedOrders ro
    WHERE ro.total_rank <= 10
),
OrderDetails AS (
    SELECT ho.o_orderkey, 
           SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
           COUNT(li.l_orderkey) AS line_item_count
    FROM HighValueOrders ho
    JOIN lineitem li ON ho.o_orderkey = li.l_orderkey
    GROUP BY ho.o_orderkey
)
SELECT ho.o_orderkey, 
       ho.o_orderstatus, 
       ho.o_totalprice, 
       ho.o_orderdate, 
       ho.o_orderpriority,
       od.total_sales, 
       od.line_item_count
FROM HighValueOrders ho
JOIN OrderDetails od ON ho.o_orderkey = od.o_orderkey
ORDER BY ho.o_orderdate DESC, total_sales DESC;