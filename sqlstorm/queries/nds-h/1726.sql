WITH CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighSpenders AS (
    SELECT c.c_custkey, c.c_name, co.total_spent, co.order_count,
           RANK() OVER (ORDER BY co.total_spent DESC) AS spend_rank
    FROM customer c
    JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE co.total_spent IS NOT NULL AND co.total_spent > 1000
),
SupplierStats AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
PartStatistics AS (
    SELECT p.p_partkey, p.p_name, AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT hs.c_name, hs.total_spent, hs.order_count, 
       ps.p_name, ps.avg_supply_cost, ps.supplier_count,
       COALESCE(ss.total_supply_cost, 0) AS total_supplier_cost
FROM HighSpenders hs
LEFT JOIN PartStatistics ps ON hs.c_custkey = ps.p_partkey
LEFT JOIN SupplierStats ss ON ps.supplier_count = ss.part_count
WHERE hs.spend_rank <= 10
ORDER BY hs.total_spent DESC, ps.p_name ASC;
