WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), FilteredOrders AS (
    SELECT o.o_orderkey, o.o_orderstatus, SUM(l.l_extendedprice) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderstatus
), SupplierRanking AS (
    SELECT r.s_suppkey, r.s_name, ROW_NUMBER() OVER (ORDER BY r.total_cost DESC) AS rank
    FROM RankedSuppliers r
)
SELECT so.o_orderkey, so.total_price, sr.s_name, sr.rank
FROM FilteredOrders so
JOIN SupplierRanking sr ON so.total_price > 100000
WHERE sr.rank <= 10
ORDER BY so.total_price DESC, sr.rank;