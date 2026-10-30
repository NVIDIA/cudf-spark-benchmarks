WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierPartRegion AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        p.p_name,
        r.r_name,
        COALESCE(SUM(ps.ps_supplycost), 0) AS total_supplycost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_name, s.s_acctbal, p.p_name, r.r_name
),
TopSuppliers AS (
    SELECT 
        sr.*,
        ROW_NUMBER() OVER (PARTITION BY sr.r_name ORDER BY sr.total_supplycost DESC) AS rn
    FROM 
        SupplierPartRegion sr
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.total_revenue,
    ts.s_name,
    ts.total_supplycost,
    ts.r_name
FROM 
    RankedOrders ro
LEFT JOIN 
    TopSuppliers ts ON ro.total_revenue > 10000 AND ts.rn <= 5
WHERE 
    ro.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
ORDER BY 
    ro.o_orderdate, ro.total_revenue DESC, ts.total_supplycost DESC;