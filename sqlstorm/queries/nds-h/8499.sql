WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueSuppliers AS (
    SELECT r.r_name, n.n_name, rs.s_suppkey, rs.s_name, rs.total_value
    FROM RankedSuppliers rs
    JOIN nation n ON rs.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE rs.total_value > (SELECT AVG(total_value) FROM RankedSuppliers)
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total_spent DESC
    LIMIT 5
)
SELECT hvs.r_name AS region_name, hvs.n_name AS nation_name, hvs.s_name AS supplier_name, 
       tc.c_name AS top_customer_name, tc.total_spent
FROM HighValueSuppliers hvs
JOIN TopCustomers tc ON hvs.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
    WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
)
ORDER BY hvs.total_value DESC, tc.total_spent DESC;