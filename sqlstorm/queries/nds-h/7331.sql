WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_nationkey, n.n_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           DENSE_RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal, n.n_nationkey, n.n_name
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, o.o_orderkey,
           o.o_orderstatus, o.o_totalprice, o.o_orderdate,
           DENSE_RANK() OVER (ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
),
RecentLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, l.l_quantity, 
           l.l_extendedprice, l.l_discount, l.l_tax, 
           RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_shipdate DESC) AS rank
    FROM lineitem l
    WHERE l.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '30 days'
)
SELECT r.n_name AS supplier_nation,
       r.s_name AS supplier_name,
       c.c_name AS customer_name,
       SUM(rl.l_extendedprice * (1 - rl.l_discount)) AS revenue,
       COUNT(DISTINCT rl.l_orderkey) AS order_count,
       AVG(c.c_acctbal) AS avg_customer_balance
FROM RankedSuppliers r
JOIN RecentLineItems rl ON r.s_suppkey = rl.l_suppkey
JOIN HighValueCustomers c ON rl.l_orderkey = c.o_orderkey
WHERE r.rank <= 5
AND c.rank <= 10
GROUP BY r.n_name, r.s_name, c.c_name
ORDER BY revenue DESC, order_count DESC
LIMIT 50;