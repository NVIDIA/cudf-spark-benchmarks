
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
        c.c_nationkey
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name, c.c_nationkey
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CompositeSales AS (
    SELECT 
        r.r_name,
        SUM(ro.total_revenue) AS region_revenue
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON ro.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.revenue_rank <= 10
    GROUP BY 
        r.r_name
)
SELECT 
    cs.r_name,
    cs.region_revenue,
    ss.s_name,
    ss.part_count,
    ss.total_supply_cost,
    CASE 
        WHEN cs.region_revenue IS NULL THEN 'No Revenue'
        ELSE 'Revenue Present'
    END AS revenue_status
FROM 
    CompositeSales cs
LEFT JOIN 
    SupplierSummary ss ON cs.r_name = (
        SELECT 
            r.r_name
        FROM 
            nation n
        JOIN 
            region r ON n.n_regionkey = r.r_regionkey
        WHERE 
            n.n_nationkey IN (SELECT DISTINCT c.c_nationkey FROM customer c)
        LIMIT 1
    )
ORDER BY 
    cs.region_revenue DESC NULLS LAST;
