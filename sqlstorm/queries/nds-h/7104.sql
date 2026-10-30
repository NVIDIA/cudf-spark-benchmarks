WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           COUNT(DISTINCT p.p_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderLineItems AS (
    SELECT o.o_orderkey, COUNT(l.l_linenumber) AS total_lines,
           SUM(l.l_quantity * l.l_extendedprice * (1 - l.l_discount)) AS total_revenue 
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY o.o_orderkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, sp.total_cost, sp.part_count
    FROM SupplierParts sp
    JOIN supplier s ON sp.s_suppkey = s.s_suppkey
    ORDER BY sp.total_cost DESC
    LIMIT 5
)
SELECT ts.s_name, ts.total_cost, ol.total_revenue, ol.total_lines
FROM TopSuppliers ts
JOIN OrderLineItems ol ON ts.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey IN (
        SELECT p.p_partkey
        FROM part p
        WHERE p.p_brand = 'Brand#23'
    )
)
ORDER BY ts.total_cost DESC, ol.total_revenue DESC;