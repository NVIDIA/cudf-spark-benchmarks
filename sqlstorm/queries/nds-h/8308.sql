WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT r.r_regionkey, r.r_name, 
           SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
    JOIN supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE rs.rank <= 5
    GROUP BY r.r_regionkey, r.r_name
)
SELECT r.r_name, 
       SUM(ts.total_supply_cost) AS region_total_supply_cost
FROM region r
JOIN TopSuppliers ts ON r.r_regionkey = ts.r_regionkey
GROUP BY r.r_name
ORDER BY region_total_supply_cost DESC
LIMIT 10;
