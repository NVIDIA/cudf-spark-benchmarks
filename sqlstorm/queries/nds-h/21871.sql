WITH RankedSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           T1.total_cost,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY T1.total_cost DESC) AS rnk
    FROM supplier s
    JOIN (
        SELECT ps.ps_suppkey,
               SUM(ps.ps_supplycost * l.l_quantity) AS total_cost
        FROM partsupp ps
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey
        GROUP BY ps.ps_suppkey
    ) T1 ON s.s_suppkey = T1.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
),
TotalOrders AS (
    SELECT c.c_custkey,
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
HighValueCustomers AS (
    SELECT c.c_custkey,
           c.c_name,
           t.total_spent,
           ROW_NUMBER() OVER (ORDER BY t.total_spent DESC) AS rnk
    FROM customer c
    JOIN TotalOrders t ON c.c_custkey = t.c_custkey
    WHERE t.total_spent > 1000.00
),
FilteredNationalData AS (
    SELECT n.n_name,
           r.r_name,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name, r.r_name
)
SELECT hc.c_name,
       hc.total_spent,
       rs.s_name,
       rs.total_cost,
       f.nd_data
FROM HighValueCustomers hc
LEFT JOIN RankedSuppliers rs ON hc.c_custkey = rs.s_suppkey
LEFT JOIN (
    SELECT f.n_name || ' in ' || f.r_name AS nd_data
    FROM FilteredNationalData f
    WHERE f.supplier_count IS NOT NULL
) f ON true
WHERE rs.rnk = 1 OR hc.rnk <= 5
ORDER BY hc.total_spent DESC, rs.total_cost ASC
LIMIT 10;
