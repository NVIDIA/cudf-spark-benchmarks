
WITH SupplierOrderInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
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
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
RankedSuppliers AS (
    SELECT 
        soi.nation_name,
        soi.s_name,
        soi.total_revenue,
        soi.order_count,
        RANK() OVER (PARTITION BY soi.nation_name ORDER BY soi.total_revenue DESC) AS revenue_rank
    FROM 
        SupplierOrderInfo soi
)
SELECT 
    r.nation_name,
    rs.s_name,
    rs.total_revenue,
    rs.order_count
FROM 
    RankedSuppliers rs
JOIN 
    (SELECT DISTINCT n_name AS nation_name FROM nation) r ON rs.nation_name = r.nation_name
WHERE 
    rs.revenue_rank <= 5
ORDER BY 
    r.nation_name, rs.total_revenue DESC;
