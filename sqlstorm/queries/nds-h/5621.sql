WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SuppliersRevenue AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
TopRegions AS (
    SELECT 
        r.r_regionkey, 
        r.r_name, 
        SUM(ro.total_revenue) AS region_revenue
    FROM 
        Region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        RankedOrders ro ON c.c_custkey = ro.o_orderkey
    GROUP BY 
        r.r_regionkey, r.r_name
    ORDER BY 
        region_revenue DESC
    LIMIT 5
)
SELECT 
    r.r_name, 
    r.region_revenue, 
    sr.supplier_total_cost
FROM 
    TopRegions r
JOIN 
    SuppliersRevenue sr ON r.r_regionkey = sr.s_suppkey
ORDER BY 
    r.region_revenue DESC;
