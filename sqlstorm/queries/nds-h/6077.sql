WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name
    FROM RankedSuppliers s
    WHERE s.total_value > (
        SELECT AVG(total_value) FROM RankedSuppliers
    )
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderstatus, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate > DATE '1995-01-01' AND l.l_shipdate < DATE '1996-01-01'
    GROUP BY o.o_orderkey, o.o_orderstatus
),
FinalReport AS (
    SELECT ts.s_suppkey, ts.s_name, SUM(os.total_sales) AS total_sales_by_supplier
    FROM TopSuppliers ts
    JOIN OrderSummary os ON os.o_orderstatus = 'F'
    GROUP BY ts.s_suppkey, ts.s_name
)
SELECT fr.s_suppkey, fr.s_name, fr.total_sales_by_supplier
FROM FinalReport fr
ORDER BY fr.total_sales_by_supplier DESC
LIMIT 10;
