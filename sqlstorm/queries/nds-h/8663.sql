
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
    HAVING SUM(ps.ps_availqty) > 1000
),
NationWiseSuppliers AS (
    SELECT n.n_name, COUNT(rs.s_suppkey) AS supplier_count, SUM(rs.total_cost) AS total_spending
    FROM RankedSuppliers rs
    JOIN nation n ON rs.s_nationkey = n.n_nationkey
    GROUP BY n.n_name
),
HighSpendingNations AS (
    SELECT n.n_name, n.n_regionkey, nws.total_spending
    FROM NationWiseSuppliers nws
    JOIN nation n ON n.n_name = nws.n_name
    WHERE nws.total_spending > (
        SELECT AVG(nws2.total_spending) FROM NationWiseSuppliers nws2
    )
)
SELECT r.r_name, COUNT(hsn.n_name) AS high_spender_count, SUM(hsn.total_spending) AS total_spending
FROM region r
JOIN HighSpendingNations hsn ON r.r_regionkey = hsn.n_regionkey
GROUP BY r.r_name
ORDER BY high_spender_count DESC, total_spending DESC;
