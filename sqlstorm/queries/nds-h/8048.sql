WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
TopSuppliers AS (
    SELECT 
        sr.s_suppkey,
        sr.supplier_revenue,
        RANK() OVER (ORDER BY sr.supplier_revenue DESC) AS revenue_rank
    FROM 
        SupplierRevenue sr
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    ts.supplier_revenue,
    ts.revenue_rank
FROM 
    RankedOrders o
JOIN 
    TopSuppliers ts ON o.o_orderkey = ts.supplier_revenue
WHERE 
    ts.revenue_rank <= 10
ORDER BY 
    o.o_orderdate DESC, ts.supplier_revenue DESC;