
WITH SupplierSummary AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
OrderSummary AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice) AS total_extended_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice
),
TopSuppliers AS (
    SELECT
        ss.s_suppkey,
        ss.s_name,
        ss.nation_name,
        ss.total_available_qty,
        ss.total_cost
    FROM SupplierSummary ss
    WHERE ss.s_suppkey IN (
        SELECT s_suppkey
        FROM SupplierSummary
        ORDER BY total_cost DESC
        LIMIT 10
    )
)
SELECT
    os.o_orderkey,
    os.o_orderdate,
    os.o_totalprice,
    ts.s_name AS supplier_name,
    ts.total_available_qty,
    ts.total_cost
FROM OrderSummary os
JOIN TopSuppliers ts ON os.total_quantity > 100
WHERE os.o_totalprice > 5000
ORDER BY os.o_orderdate DESC, ts.total_cost DESC;
