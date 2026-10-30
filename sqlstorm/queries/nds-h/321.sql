WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
TotalOrderValues AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT r.s_name, r.s_acctbal, h.c_name, 
       COALESCE(t.total_value, 0) AS total_order_value,
       CASE 
           WHEN h.customer_rank <= 10 THEN 'High Value'
           ELSE 'Regular'
       END AS customer_status
FROM RankedSuppliers r
LEFT JOIN HighValueCustomers h ON r.s_suppkey = h.c_custkey
LEFT JOIN TotalOrderValues t ON h.c_custkey = t.o_orderkey
WHERE r.rank = 1 AND r.s_acctbal IS NOT NULL
ORDER BY r.s_acctbal DESC, h.c_name;
