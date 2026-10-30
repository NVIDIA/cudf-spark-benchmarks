WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        n.n_name
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.rank <= 3 AND n.n_nationkey = rs.s_suppkey
),
OrderTotals AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_linenumber) AS total_lines
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND
        l.l_shipdate > '1997-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    n.n_name,
    COALESCE(ts.s_name, 'No Supplier') AS supplier_name,
    SUM(ot.total_price) AS total_revenue,
    COUNT(ot.o_orderkey) AS total_orders,
    AVG(ot.total_lines) AS avg_lines_per_order
FROM 
    nation n
LEFT JOIN 
    TopSuppliers ts ON n.n_nationkey = ts.s_suppkey
LEFT JOIN 
    OrderTotals ot ON ts.s_suppkey = ot.o_orderkey
WHERE 
    n.n_name LIKE 'A%' OR n.n_name IS NULL
GROUP BY 
    n.n_name, ts.s_name
HAVING 
    SUM(ot.total_price) > 10000
ORDER BY 
    total_revenue DESC;