WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderpriority, 
           RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS rank_order
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
), 
CustomerDetails AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, n.n_name AS nation_name 
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE c.c_acctbal > 500.00
), 
LineItemAggregates AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, 
           SUM(l.l_quantity) AS total_quantity 
    FROM lineitem l
    GROUP BY l.l_orderkey
),
FinalResult AS (
    SELECT coalesce(c.c_name, 'Unknown') AS customer_name, 
           r.o_orderkey, 
           r.o_orderdate, 
           r.o_totalprice, 
           la.total_sales, 
           la.total_quantity, 
           r.o_orderpriority
    FROM RankedOrders r
    LEFT JOIN CustomerDetails c ON r.o_orderkey = c.c_custkey
    LEFT JOIN LineItemAggregates la ON r.o_orderkey = la.l_orderkey
    WHERE r.rank_order <= 10
)
SELECT f.customer_name, f.o_orderkey, f.o_orderdate, f.o_totalprice, 
       f.total_sales, f.total_quantity, f.o_orderpriority 
FROM FinalResult f
ORDER BY f.o_totalprice DESC, f.o_orderdate ASC;