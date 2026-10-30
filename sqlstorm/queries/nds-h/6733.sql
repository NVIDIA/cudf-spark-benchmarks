WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
RegionAnalysis AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    ro.o_orderkey, 
    ro.o_orderdate, 
    ro.total_revenue, 
    ts.s_name AS top_supplier_name, 
    ts.total_supplycost,
    ra.r_name, 
    ra.nation_count, 
    ra.total_order_value
FROM 
    RankedOrders ro
JOIN 
    TopSuppliers ts ON ts.total_supplycost = (SELECT MAX(total_supplycost) FROM TopSuppliers)
JOIN 
    RegionAnalysis ra ON ra.r_regionkey = (SELECT MAX(r.r_regionkey) FROM region r)
WHERE 
    ro.revenue_rank = 1
ORDER BY 
    ro.total_revenue DESC, 
    ts.total_supplycost ASC
LIMIT 100;
