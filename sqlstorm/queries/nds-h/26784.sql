WITH SupplierOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerAnalysis AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
),
RegionStats AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(ca.total_orders) AS orders_in_region,
        SUM(ca.total_spent) AS revenue_in_region
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        CustomerAnalysis ca ON n.n_nationkey = ca.c_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    so.s_name,
    rs.r_name,
    so.total_quantity,
    so.total_revenue,
    rs.orders_in_region,
    rs.revenue_in_region
FROM 
    SupplierOrders so
JOIN 
    RegionStats rs ON so.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
        WHERE l.l_extendedprice > (SELECT AVG(l_extendedprice) FROM lineitem)
    )
ORDER BY 
    rs.revenue_in_region DESC, so.total_revenue DESC;
