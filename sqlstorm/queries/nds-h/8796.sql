WITH SupplierOrders AS (
    SELECT 
        s.s_name AS supplier_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1996-12-31'
    GROUP BY 
        s.s_name
),
RankedSuppliers AS (
    SELECT 
        supplier_name, 
        total_revenue, 
        order_count,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        SupplierOrders
)
SELECT 
    r.supplier_name,
    r.total_revenue,
    r.order_count,
    r.revenue_rank
FROM 
    RankedSuppliers r
WHERE 
    r.revenue_rank <= 10
ORDER BY 
    r.total_revenue DESC;