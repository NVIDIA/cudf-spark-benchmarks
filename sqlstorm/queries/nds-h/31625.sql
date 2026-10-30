WITH  SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, ps.ps_supplycost, ps.ps_availqty, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY ps.ps_supplycost DESC) AS supply_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
), RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS acctbal_rank
    FROM customer c
), HighValueOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
), OrderDetails AS (
    SELECT o.o_orderkey, o.o_custkey, r.r_name,
           COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
           AVG(l.l_discount) AS avg_discount
    FROM HighValueOrders ho
    JOIN orders o ON ho.o_orderkey = o.o_orderkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY o.o_orderkey, o.o_custkey, r.r_name
)
SELECT od.o_orderkey, od.o_custkey, od.total_quantity, od.avg_discount, 
       s.s_name AS supplier_name, s.supply_rank, 
       rc.acctbal_rank
FROM OrderDetails od
LEFT JOIN SupplyChain s ON od.o_custkey = s.s_nationkey
LEFT JOIN RankedCustomers rc ON od.o_custkey = rc.c_custkey
WHERE (supply_rank <= 3 OR rc.acctbal_rank <= 5)
  AND (od.total_quantity IS NOT NULL AND od.total_quantity > 0)
ORDER BY od.total_quantity DESC, rc.acctbal_rank, s.s_name;
