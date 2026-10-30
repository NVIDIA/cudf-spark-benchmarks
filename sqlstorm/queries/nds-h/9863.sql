
WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, r.r_name AS region_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name, r.r_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.nation_name, s.region_name, s.total_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY s.region_name ORDER BY s.total_supply_cost DESC) AS rank
    FROM SupplierDetails s
)
SELECT o.o_orderkey, o.o_orderdate, c.c_name, t.s_name, t.total_supply_cost
FROM orders o
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN TopSuppliers t ON l.l_suppkey = t.s_suppkey
JOIN customer c ON o.o_custkey = c.c_custkey
WHERE t.rank <= 5
  AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
ORDER BY t.region_name, t.total_supply_cost DESC;
