WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rnk
    FROM 
        supplier s
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_nationkey
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rnk <= 5
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        c.c_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey, c.c_custkey, c.c_nationkey
),
SupplierRevenue AS (
    SELECT 
        ts.s_suppkey,
        ts.s_name,
        SUM(od.total_revenue) AS total_supplier_revenue
    FROM 
        OrderDetails od
    JOIN 
        partsupp ps ON od.o_orderkey = ps.ps_partkey
    JOIN 
        TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
    GROUP BY 
        ts.s_suppkey, ts.s_name
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    sr.total_supplier_revenue
FROM 
    TopSuppliers ts
LEFT JOIN 
    SupplierRevenue sr ON ts.s_suppkey = sr.s_suppkey
ORDER BY 
    ts.s_suppkey;