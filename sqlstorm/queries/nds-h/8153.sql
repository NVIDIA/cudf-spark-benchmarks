WITH SupplierOrders AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
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
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
), RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        so.total_revenue, 
        RANK() OVER (ORDER BY so.total_revenue DESC) AS revenue_rank
    FROM 
        SupplierOrders so
    JOIN 
        supplier s ON so.s_suppkey = s.s_suppkey
)
SELECT 
    rs.s_suppkey, 
    rs.s_name, 
    rs.total_revenue
FROM 
    RankedSuppliers rs
WHERE 
    rs.revenue_rank <= 10
ORDER BY 
    rs.total_revenue DESC;