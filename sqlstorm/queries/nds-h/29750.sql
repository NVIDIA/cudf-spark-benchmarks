WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_within_nation
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT s.*, 
           CONCAT(s.s_name, ' (', n.n_name, ')') AS supplier_info
    FROM RankedSuppliers s
    JOIN nation n ON s.nation_name = n.n_name
    WHERE s.rank_within_nation <= 3
)
SELECT 
    p.p_name,
    ts.supplier_info,
    SUM(ps.ps_availqty) AS total_available_qty
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
GROUP BY p.p_name, ts.supplier_info
ORDER BY total_available_qty DESC
LIMIT 10;
