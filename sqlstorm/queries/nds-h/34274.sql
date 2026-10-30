WITH  SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_returnflag = 'N'
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.total_order_value) AS total_spent
    FROM CustomerOrders o
    JOIN customer c ON o.c_custkey = c.c_custkey
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total_spent DESC
    LIMIT 10
)
SELECT r.r_name, 
       COUNT(DISTINCT sc.s_suppkey) AS total_suppliers, 
       COUNT(DISTINCT tc.c_custkey) AS top_customers_count,
       AVG(sc.ps_supplycost) AS avg_supply_cost
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplyChain sc ON s.s_suppkey = sc.s_suppkey
LEFT JOIN TopCustomers tc ON s.s_suppkey = tc.c_custkey
WHERE r.r_name LIKE '%Americas%' OR (n.n_name IS NULL)
GROUP BY r.r_name
ORDER BY total_suppliers DESC, avg_supply_cost ASC;
