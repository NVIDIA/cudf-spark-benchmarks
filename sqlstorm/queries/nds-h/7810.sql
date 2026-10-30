
WITH SupplierDemand AS (
    SELECT s.s_suppkey, SUM(l.l_quantity) AS total_quantity
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey
),
NationRegion AS (
    SELECT n.n_nationkey, r.r_regionkey
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
SupplierRegion AS (
    SELECT nr.n_nationkey, s.s_suppkey
    FROM SupplierDemand sd
    JOIN supplier s ON sd.s_suppkey = s.s_suppkey
    JOIN NationRegion nr ON s.s_nationkey = nr.n_nationkey
)
SELECT r.r_name, COUNT(DISTINCT sr.s_suppkey) AS supplier_count, 
       SUM(cd.total_spent) AS total_customer_spending
FROM region r
JOIN NationRegion nr ON r.r_regionkey = nr.r_regionkey
JOIN SupplierRegion sr ON nr.n_nationkey = sr.n_nationkey
JOIN CustomerOrders cd ON cd.c_custkey IN (
    SELECT c.c_custkey
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
)
GROUP BY r.r_name
ORDER BY total_customer_spending DESC, supplier_count DESC
LIMIT 10;
