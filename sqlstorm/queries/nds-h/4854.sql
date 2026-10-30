
WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderstatus = 'O'
),
SupplierStats AS (
    SELECT ps.ps_partkey,
           s.s_nationkey,
           SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_nationkey
),
CustomerNations AS (
    SELECT n.n_nationkey,
           n.n_name,
           COUNT(DISTINCT c.c_custkey) AS num_customers
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
FinalReport AS (
    SELECT RANK() OVER (ORDER BY O.o_totalprice DESC) AS price_rank,
           C.n_name AS customer_nation,
           COALESCE(S.total_avail_qty, 0) AS available_quantity,
           COALESCE(S.avg_supply_cost, 0) AS average_supply_cost,
           O.o_orderdate
    FROM RankedOrders O
    LEFT JOIN SupplierStats S ON O.o_orderkey = S.ps_partkey 
    JOIN CustomerNations C ON S.s_nationkey = C.n_nationkey
    WHERE O.rn = 1
)

SELECT F.customer_nation,
       SUM(F.available_quantity) AS total_available_quantity,
       AVG(F.average_supply_cost) AS avg_supply_cost_per_nation,
       COUNT(DISTINCT F.price_rank) AS unique_price_ranks
FROM FinalReport F
WHERE F.o_orderdate >= '1997-01-01'
GROUP BY F.customer_nation
HAVING SUM(F.available_quantity) > 1000
ORDER BY total_available_quantity DESC;
