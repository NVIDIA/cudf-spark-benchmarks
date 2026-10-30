WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        r.r_name, 
        ts.s_name, 
        ts.total_cost
    FROM RankedSuppliers ts
    JOIN region r ON ts.rank <= 3
    WHERE ts.rank IS NOT NULL
)
SELECT 
    r_name, 
    s_name, 
    total_cost
FROM TopSuppliers
ORDER BY r_name, total_cost DESC;
