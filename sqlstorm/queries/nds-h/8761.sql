WITH TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY TotalCost DESC
    LIMIT 10
), HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_name, c.c_nationkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > 1000
), LineItemSummary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    t.s_name AS SupplierName,
    h.c_name AS CustomerName,
    h.o_orderkey AS OrderKey,
    h.o_totalprice AS TotalPrice,
    h.o_orderdate AS OrderDate,
    l.Revenue AS RevenueGenerated
FROM TopSuppliers t
JOIN HighValueOrders h ON TRUE
JOIN LineItemSummary l ON h.o_orderkey = l.l_orderkey
WHERE h.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
AND t.TotalCost > 10000
ORDER BY t.TotalCost DESC, l.Revenue DESC;