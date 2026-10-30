WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank_by_balance
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 1000
),
TopSuppliers AS (
    SELECT 
        s_suppkey,
        s_name,
        s_acctbal
    FROM 
        RankedSuppliers
    WHERE 
        rank_by_balance <= 5
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        COUNT(DISTINCT l.l_orderkey) AS num_lineitems,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
SupplierLineItems AS (
    SELECT 
        s.s_suppkey,
        o.o_orderkey,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        s.s_suppkey, o.o_orderkey
)
SELECT 
    n.n_name AS nation_name,
    SUM(od.total_revenue) AS total_revenue,
    COUNT(DISTINCT od.o_orderkey) AS distinct_order_count,
    COALESCE(MAX(sl.total_quantity), 0) AS max_quantity_by_supplier,
    COUNT(DISTINCT ss.s_suppkey) AS supplier_count
FROM 
    OrderDetails od
LEFT JOIN 
    SupplierLineItems sl ON od.o_orderkey = sl.o_orderkey
JOIN 
    TopSuppliers ss ON sl.s_suppkey = ss.s_suppkey
JOIN 
    supplier s ON ss.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    n.n_name
HAVING 
    SUM(od.total_revenue) > 50000
ORDER BY 
    total_revenue DESC;
