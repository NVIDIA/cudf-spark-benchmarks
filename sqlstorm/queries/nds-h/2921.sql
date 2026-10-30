
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        RankedSuppliers s
    WHERE 
        rank = 1
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS item_count,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    c.c_name,
    SUM(os.total_sales) AS total_revenue,
    COUNT(DISTINCT os.o_orderkey) AS complete_order_count,
    COALESCE(MAX(ts.s_acctbal), 0) AS top_supplier_acctbal,
    AVG(COALESCE(ts.s_acctbal, 0)) AS avg_supplier_acctbal
FROM 
    customer c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    OrderSummary os ON o.o_orderkey = os.o_orderkey
LEFT JOIN 
    TopSuppliers ts ON c.c_nationkey = ts.s_suppkey
WHERE 
    o.o_orderstatus <> 'L'
GROUP BY 
    c.c_name
HAVING 
    SUM(os.total_sales) > 10000
ORDER BY 
    total_revenue DESC;
