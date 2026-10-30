WITH RankedSuppliers AS (
    SELECT s.s_name, s.s_nationkey, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT r.r_name, rs.s_name, SUM(p.p_retailprice) AS total_retail_price
    FROM RankedSuppliers rs
    JOIN nation n ON rs.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN lineitem l ON l.l_suppkey = rs.s_nationkey
    JOIN part p ON l.l_partkey = p.p_partkey
    WHERE rs.rnk <= 5
    GROUP BY r.r_name, rs.s_name
)
SELECT r_name, s_name, total_retail_price
FROM TopSuppliers
ORDER BY r_name, total_retail_price DESC;
