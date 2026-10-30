WITH SupplierOrderDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(l.l_quantity) AS total_quantity
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
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
), RankSuppliers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY nation ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        SupplierOrderDetails
)
SELECT 
    nation,
    s_suppkey,
    s_name,
    total_revenue,
    total_orders,
    total_quantity
FROM 
    RankSuppliers
WHERE 
    revenue_rank <= 5
ORDER BY 
    nation, total_revenue DESC;