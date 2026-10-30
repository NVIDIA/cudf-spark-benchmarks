
WITH RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_custkey
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_custkey
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
    ORDER BY 
        total_supplycost DESC
    LIMIT 5
),
RevenueByRegion AS (
    SELECT 
        r.r_name,
        SUM(ro.total_revenue) AS region_revenue
    FROM 
        RecentOrders ro
    JOIN 
        customer c ON ro.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name,
    r.region_revenue,
    ts.s_name,
    ts.total_supplycost
FROM 
    RevenueByRegion r
JOIN 
    TopSuppliers ts ON r.r_name = (
        SELECT r2.r_name 
        FROM region r2 
        JOIN nation n ON r2.r_regionkey = n.n_regionkey 
        JOIN customer c ON n.n_nationkey = c.c_nationkey 
        WHERE c.c_custkey = (SELECT MIN(c2.c_custkey) FROM customer c2)
        LIMIT 1
    )
ORDER BY 
    r.region_revenue DESC, ts.total_supplycost DESC;
