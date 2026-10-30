
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    c.c_name,
    c.c_acctbal,
    fr.total_revenue,
    rs.s_name AS highest_supplier_name,
    rs.s_acctbal AS highest_supplier_acctbal
FROM 
    customer c
LEFT JOIN 
    FilteredOrders fr ON c.c_custkey = fr.o_custkey
LEFT JOIN 
    RankedSuppliers rs ON rs.rn = 1 AND c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
WHERE 
    fr.total_revenue IS NOT NULL
ORDER BY 
    fr.total_revenue DESC, c.c_acctbal;
