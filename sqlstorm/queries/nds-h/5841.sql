WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        rs.nation_name
    FROM RankedSuppliers rs
    JOIN supplier s ON rs.s_suppkey = s.s_suppkey
    WHERE rs.rank <= 5
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS total_items,
        c.c_mktsegment
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY o.o_orderkey, o.o_custkey, c.c_mktsegment
),
SupplierOrderSummary AS (
    SELECT 
        ts.s_suppkey,
        ts.s_name,
        os.total_revenue,
        os.total_items,
        os.c_mktsegment
    FROM TopSuppliers ts
    JOIN partsupp ps ON ts.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN OrderSummary os ON l.l_orderkey = os.o_orderkey
)
SELECT 
    ts.nation_name,
    SUM(sos.total_revenue) AS total_revenue,
    COUNT(sos.s_suppkey) AS supplier_count,
    AVG(sos.total_items) AS avg_items_per_order
FROM SupplierOrderSummary sos
JOIN TopSuppliers ts ON sos.s_suppkey = ts.s_suppkey
GROUP BY ts.nation_name
ORDER BY total_revenue DESC;