WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, rs.total_supply_cost
    FROM RankedSuppliers rs
    JOIN supplier s ON rs.s_suppkey = s.s_suppkey
    ORDER BY rs.total_supply_cost DESC
    LIMIT 10
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, l.l_partkey, l.l_quantity, l.l_extendedprice
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
)
SELECT ts.s_name, od.o_orderkey, od.o_orderdate, od.o_totalprice, 
       SUM(od.l_extendedprice * od.l_quantity * (1 - l.l_discount / 100)) AS finalized_price
FROM TopSuppliers ts
JOIN partsupp ps ON ts.s_suppkey = ps.ps_suppkey
JOIN lineitem l ON ps.ps_partkey = l.l_partkey
JOIN OrderDetails od ON l.l_orderkey = od.o_orderkey
WHERE l.l_shipdate >= '1997-01-01'
GROUP BY ts.s_name, od.o_orderkey, od.o_orderdate, od.o_totalprice
ORDER BY ts.s_name, finalized_price DESC;