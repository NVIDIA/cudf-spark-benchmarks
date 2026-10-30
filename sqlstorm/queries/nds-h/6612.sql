WITH SupplierOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        so.total_quantity,
        so.total_revenue,
        RANK() OVER (ORDER BY so.total_revenue DESC) AS supplier_rank
    FROM 
        SupplierOrders so
    JOIN 
        supplier s ON so.s_suppkey = s.s_suppkey
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.total_quantity,
    ts.total_revenue
FROM 
    TopSuppliers ts
WHERE 
    ts.supplier_rank <= 5
ORDER BY 
    ts.total_revenue DESC;