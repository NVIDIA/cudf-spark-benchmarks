WITH CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, 
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), TopCustomers AS (
    SELECT c.c_custkey, c.c_name, co.total_spent
    FROM CustomerOrders co
    JOIN customer c ON c.c_custkey = co.c_custkey
    WHERE co.total_spent > (
        SELECT AVG(total_spent) 
        FROM CustomerOrders
    )
), SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, 
           ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
), FinalSummary AS (
    SELECT r.r_name, 
           COUNT(DISTINCT t.c_custkey) AS customer_count,
           COUNT(DISTINCT sp.p_partkey) AS part_count, 
           SUM(sp.ps_supplycost * sp.ps_availqty) AS total_supply_value
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN SupplierParts sp ON s.s_suppkey = sp.s_suppkey
    LEFT JOIN TopCustomers t ON s.s_nationkey = t.c_custkey
    GROUP BY r.r_name
)
SELECT fs.r_name, fs.customer_count, fs.part_count, fs.total_supply_value,
       ROW_NUMBER() OVER (ORDER BY fs.total_supply_value DESC) AS rank
FROM FinalSummary fs
WHERE fs.total_supply_value IS NOT NULL
ORDER BY fs.customer_count DESC, fs.part_count DESC;
