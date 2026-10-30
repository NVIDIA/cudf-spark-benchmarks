
WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, n.n_name AS nation_name, 
           COUNT(DISTINCT ps.ps_partkey) AS part_count,
           SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_address, n.n_name
),
HighestSuppliers AS (
    SELECT s.*
    FROM SupplierDetails s
    WHERE s.part_count = (SELECT MAX(part_count) FROM SupplierDetails)
),
OrdersBySuppliers AS (
    SELECT o.o_orderkey, o.o_totalprice, d.s_name, d.nation_name
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN HighestSuppliers d ON l.l_suppkey = d.s_suppkey
)
SELECT d.s_name, d.nation_name, COUNT(o.o_orderkey) AS order_count,
       SUM(o.o_totalprice) AS total_spent
FROM OrdersBySuppliers o
JOIN HighestSuppliers d ON o.s_name = d.s_name
GROUP BY d.s_name, d.nation_name
ORDER BY total_spent DESC;
