WITH SupplierPartCounts AS (
    SELECT s.s_suppkey, COUNT(ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, spc.part_count
    FROM supplier s
    JOIN SupplierPartCounts spc ON s.s_suppkey = spc.s_suppkey
    WHERE spc.part_count > 5
    ORDER BY spc.part_count DESC
    LIMIT 10
),
CustomerOrderCounts AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, coc.order_count
    FROM customer c
    JOIN CustomerOrderCounts coc ON c.c_custkey = coc.c_custkey
    WHERE coc.order_count > 3
    ORDER BY coc.order_count DESC
    LIMIT 10
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    tc.c_custkey,
    tc.c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM TopSuppliers ts
JOIN partsupp ps ON ts.s_suppkey = ps.ps_suppkey
JOIN lineitem l ON ps.ps_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN TopCustomers tc ON o.o_custkey = tc.c_custkey
WHERE o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY ts.s_suppkey, ts.s_name, tc.c_custkey, tc.c_name
ORDER BY total_revenue DESC;