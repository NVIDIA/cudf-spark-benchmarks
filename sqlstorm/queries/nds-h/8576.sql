WITH RankedSuppliers AS (
    SELECT s.s_name, n.n_name AS nation_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT * FROM RankedSuppliers WHERE rank <= 5
),
BestSellingParts AS (
    SELECT p.p_name, SUM(l.l_quantity) AS total_quantity_sold
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= '1997-01-01'
    GROUP BY p.p_name
    ORDER BY total_quantity_sold DESC
    LIMIT 10
)
SELECT ts.nation_name, ts.s_name, bp.p_name, bp.total_quantity_sold
FROM TopSuppliers ts
JOIN BestSellingParts bp ON ts.total_supply_cost > 10000
ORDER BY ts.nation_name, ts.total_supply_cost DESC, bp.total_quantity_sold DESC;