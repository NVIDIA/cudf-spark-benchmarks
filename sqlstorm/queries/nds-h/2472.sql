
WITH SupplierCost AS (
    SELECT ps_suppkey, SUM(ps_supplycost * ps_availqty) AS total_cost
    FROM partsupp
    GROUP BY ps_suppkey
),
HighValueOrders AS (
    SELECT o_orderkey, o_custkey, o_totalprice
    FROM orders
    WHERE o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
),
CustomerOrderCount AS (
    SELECT o_custkey, COUNT(o_orderkey) AS order_count
    FROM orders
    GROUP BY o_custkey
),
RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           DENSE_RANK() OVER (ORDER BY COUNT(o.o_orderkey) DESC) AS rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
NationSuppliers AS (
    SELECT n.n_name, s.s_suppkey, MAX(s.s_acctbal) AS max_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name, s.s_suppkey
)
SELECT 
    n.n_name AS nation_name,
    rc.c_name AS customer_name,
    rc.order_count,
    sc.total_cost,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM RankedCustomers rc
JOIN HighValueOrders ho ON rc.c_custkey = ho.o_custkey
LEFT JOIN CustomerOrderCount oc ON rc.c_custkey = oc.o_custkey
JOIN lineitem l ON ho.o_orderkey = l.l_orderkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN SupplierCost sc ON ps.ps_suppkey = sc.ps_suppkey
JOIN nation n ON rc.c_custkey = n.n_nationkey
WHERE sc.total_cost > (SELECT AVG(total_cost) FROM SupplierCost)
GROUP BY n.n_name, rc.c_name, rc.order_count, sc.total_cost, p.p_name
HAVING COUNT(DISTINCT l.l_orderkey) > 10
ORDER BY revenue DESC, rc.order_count ASC;
