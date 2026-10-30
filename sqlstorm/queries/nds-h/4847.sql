WITH RankedSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_within_nation
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT c.c_custkey,
           c.c_name,
           co.total_spent
    FROM customer c
    JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
),
LineitemStats AS (
    SELECT l.l_partkey,
           SUM(l.l_quantity) AS total_quantity,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM lineitem l
    WHERE l.l_shipdate < cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY l.l_partkey
)
SELECT p.p_partkey,
       p.p_name,
       COALESCE(s.total_cost, 0) AS supplier_total_cost,
       l.total_quantity,
       l.net_revenue,
       CASE 
           WHEN hc.total_spent IS NOT NULL THEN 'High Value'
           ELSE 'Regular'
       END AS customer_status
FROM part p
LEFT JOIN RankedSuppliers s ON p.p_partkey = s.s_suppkey
LEFT JOIN LineitemStats l ON p.p_partkey = l.l_partkey
LEFT JOIN HighValueCustomers hc ON s.s_suppkey = hc.c_custkey
WHERE p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
  AND (s.rank_within_nation <= 5 OR s.rank_within_nation IS NULL)
ORDER BY p.p_partkey;