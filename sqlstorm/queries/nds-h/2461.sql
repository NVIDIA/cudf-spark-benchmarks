
WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01'
),
CustomerStats AS (
    SELECT c.c_custkey,
           c.c_name,
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
ProductAnalysis AS (
    SELECT p.p_partkey,
           p.p_name,
           AVG(p.p_retailprice) AS avg_retailprice,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           SUM(l.l_quantity) AS total_quantity_sold
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT cs.c_name,
       cs.total_spent,
       cs.total_orders,
       pa.p_name,
       pa.avg_retailprice,
       pa.total_quantity_sold,
       COALESCE(sp.total_supply_value, 0) AS total_supply_value,
       CASE 
           WHEN cs.total_spent > 10000 THEN 'VIP' 
           ELSE 'Regular' 
       END AS customer_tier
FROM CustomerStats cs
JOIN RankedOrders ro ON cs.c_custkey = ro.o_orderkey
LEFT JOIN ProductAnalysis pa ON pa.total_quantity_sold > 50
LEFT JOIN SupplierParts sp ON sp.total_supply_value > 50000
WHERE ro.order_rank <= 10
ORDER BY cs.total_spent DESC, pa.total_quantity_sold ASC;
