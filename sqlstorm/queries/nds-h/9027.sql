WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, 
        o.o_orderdate
),
HighRevenueNations AS (
    SELECT 
        n.n_name,
        SUM(ro.revenue) AS total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.o_orderkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
    HAVING 
        SUM(ro.revenue) > 1000000
),
SupplierStats AS (
    SELECT 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
    ORDER BY 
        total_supplycost DESC
)
SELECT 
    rn.n_name AS Nation, 
    ss.s_name AS Supplier, 
    ss.total_supplycost AS TotalSupplyCost
FROM 
    HighRevenueNations rn
JOIN 
    SupplierStats ss ON rn.total_revenue > 500000
ORDER BY 
    rn.total_revenue DESC, 
    ss.total_supplycost ASC
LIMIT 10;