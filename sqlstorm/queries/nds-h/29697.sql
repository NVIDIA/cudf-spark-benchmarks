
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
SupplierDetails AS (
    SELECT r.r_name, n.n_name, rs.s_name, rs.rank, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM RankedSuppliers rs
    JOIN nation n ON rs.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON rs.s_suppkey = ps.ps_suppkey
    WHERE rs.rank <= 5
    GROUP BY r.r_name, n.n_name, rs.s_name, rs.rank
)
SELECT r_name, n_name, s_name, rank, total_supply_cost,
       CONCAT(s_name, ' from ', n_name, ' in ', r_name, ' provides a total supply cost of $', 
              CAST(total_supply_cost AS DECIMAL(10, 2))) AS description
FROM SupplierDetails
ORDER BY r_name, n_name, rank;
