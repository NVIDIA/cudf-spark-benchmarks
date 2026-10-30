WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), 
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.ps_availqty, ps.ps_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
), 
OrderDetails AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, l.l_partkey, l.l_quantity, l.l_extendedprice, l.l_discount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
), 
AggregatedOrderDetails AS (
    SELECT od.o_orderkey, od.o_custkey, od.o_orderdate, SUM(od.l_extendedprice * (1 - od.l_discount)) AS total_revenue
    FROM OrderDetails od
    GROUP BY od.o_orderkey, od.o_custkey, od.o_orderdate
), 
FinalSummary AS (
    SELECT sd.nation_name, COUNT(DISTINCT ad.o_orderkey) AS total_orders, SUM(ad.total_revenue) AS total_revenue
    FROM AggregatedOrderDetails ad
    JOIN customer c ON ad.o_custkey = c.c_custkey
    JOIN SupplierDetails sd ON c.c_nationkey = sd.s_nationkey
    GROUP BY sd.nation_name
)
SELECT nation_name, total_orders, total_revenue
FROM FinalSummary
WHERE total_revenue > (
    SELECT AVG(total_revenue) 
    FROM FinalSummary
)
ORDER BY total_revenue DESC
LIMIT 10;
