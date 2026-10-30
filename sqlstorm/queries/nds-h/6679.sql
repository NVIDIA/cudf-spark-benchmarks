WITH SupplierOrders AS (
    SELECT 
        s.s_name,
        n.n_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
        AND l.l_shipmode IN ('MAIL', 'SHIP')
    GROUP BY 
        s.s_name, n.n_name
),
RankedSuppliers AS (
    SELECT 
        s_name,
        n_name,
        total_orders,
        total_revenue,
        RANK() OVER (PARTITION BY n_name ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        SupplierOrders
)
SELECT 
    n_name,
    s_name,
    total_orders,
    total_revenue,
    revenue_rank
FROM 
    RankedSuppliers
WHERE 
    revenue_rank <= 5
ORDER BY 
    n_name, revenue_rank;