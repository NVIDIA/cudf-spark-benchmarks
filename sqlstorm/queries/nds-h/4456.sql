WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, c.c_name, c.c_nationkey
),
SupplierRevenue AS (
    SELECT 
        p.p_partkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_revenue
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        p.p_partkey, s.s_name
)
SELECT 
    ro.o_orderkey,
    ro.c_name,
    ro.total_revenue,
    sr.supplier_revenue,
    CASE 
        WHEN sr.supplier_revenue IS NULL THEN 'No Revenue'
        WHEN ro.total_revenue > COALESCE(sr.supplier_revenue, 0) THEN 'Higher'
        ELSE 'Lower'
    END AS revenue_comparison
FROM 
    RankedOrders ro
LEFT JOIN 
    SupplierRevenue sr ON ro.o_orderkey = sr.p_partkey
WHERE 
    ro.revenue_rank <= 5
ORDER BY 
    ro.total_revenue DESC, ro.o_orderkey;