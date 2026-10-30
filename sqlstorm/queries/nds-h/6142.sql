WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, rs.total_cost
    FROM RankedSuppliers rs
    JOIN supplier s ON rs.s_suppkey = s.s_suppkey
    WHERE rs.total_cost > (SELECT AVG(total_cost) FROM RankedSuppliers)
    ORDER BY rs.total_cost DESC
    LIMIT 10
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
)
SELECT co.c_custkey, co.c_name, co.o_orderkey, co.o_orderdate, co.o_totalprice, ts.s_name, ts.total_cost
FROM CustomerOrders co
JOIN lineitem li ON co.o_orderkey = li.l_orderkey
JOIN TopSuppliers ts ON li.l_suppkey = ts.s_suppkey
WHERE li.l_shipdate > co.o_orderdate
ORDER BY co.o_orderdate, co.c_custkey;