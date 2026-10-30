WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
), SupplierRanking AS (
    SELECT r.s_suppkey, r.s_name, ROW_NUMBER() OVER (ORDER BY r.total_supplycost DESC) AS rank
    FROM RankedSuppliers r
)
SELECT o.o_orderkey, o.o_orderdate, o.total_price, sr.s_name
FROM OrderSummary o
JOIN SupplierRanking sr ON sr.rank <= 5
WHERE o.total_price > (SELECT AVG(total_price) FROM OrderSummary)
ORDER BY o.o_orderdate DESC, o.total_price DESC;