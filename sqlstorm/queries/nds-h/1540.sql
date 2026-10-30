WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
HighValueOrders AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        SUM(total_revenue) AS total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.o_orderkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.order_rank <= 10
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    hv.region_name,
    hv.nation_name,
    hv.total_revenue,
    CASE 
        WHEN hv.total_revenue IS NULL THEN 'No Revenue'
        ELSE CAST(hv.total_revenue AS varchar(20))
    END AS revenue_status
FROM 
    HighValueOrders hv
FULL OUTER JOIN 
    region rg ON hv.region_name = rg.r_name
WHERE 
    (hv.total_revenue > 10000 OR hv.total_revenue IS NULL)
ORDER BY 
    hv.total_revenue DESC NULLS LAST;