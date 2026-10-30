WITH SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
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
        AND l.l_returnflag = 'N'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT 
        sr.s_suppkey,
        sr.s_name,
        sr.total_revenue,
        sr.order_count,
        RANK() OVER (ORDER BY sr.total_revenue DESC) AS revenue_rank
    FROM 
        SupplierRevenue sr
)
SELECT 
    r.r_name,
    ns.n_name,
    rs.s_name,
    rs.total_revenue,
    rs.order_count,
    COALESCE(ps.ps_supplycost, 0) AS supply_cost
FROM 
    RankedSuppliers rs
LEFT JOIN 
    supplier s ON rs.s_suppkey = s.s_suppkey
LEFT JOIN 
    nation ns ON s.s_nationkey = ns.n_nationkey
LEFT JOIN 
    region r ON ns.n_regionkey = r.r_regionkey
LEFT JOIN 
    partsupp ps ON ps.ps_suppkey = rs.s_suppkey
WHERE 
    rs.revenue_rank <= 10
    AND (ps.ps_availqty IS NULL OR ps.ps_availqty > 0)
ORDER BY 
    rs.total_revenue DESC, 
    ns.n_name ASC;