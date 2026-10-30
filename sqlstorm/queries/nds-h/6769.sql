WITH SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost, 
           COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F' AND l.l_shipdate BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    GROUP BY o.o_orderkey, o.o_custkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(os.total_sales) AS total_spent
    FROM customer c
    JOIN OrderStats os ON c.c_custkey = os.o_custkey
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total_spent DESC
    LIMIT 5
)
SELECT t.c_custkey, t.c_name, t.total_spent, ss.s_name, ss.total_cost, ss.part_count
FROM TopCustomers t
JOIN SupplierStats ss ON ss.part_count >= (SELECT COUNT(DISTINCT ps.ps_partkey) / 10 FROM partsupp ps)
ORDER BY t.total_spent DESC, ss.total_cost ASC;
