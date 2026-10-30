WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts,
        COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
        AND l.l_shipdate IS NOT NULL
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRegions AS (
    SELECT 
        n.n_regionkey,
        SUM(os.total_revenue) AS region_revenue
    FROM 
        OrderSummary os
    JOIN 
        customer c ON c.c_custkey = os.o_orderkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_regionkey
),
RankedRegions AS (
    SELECT 
        r.r_name,
        tr.region_revenue,
        RANK() OVER (ORDER BY tr.region_revenue DESC) AS revenue_rank
    FROM 
        TopRegions tr 
    JOIN 
        region r ON tr.n_regionkey = r.r_regionkey
)
SELECT 
    rr.r_name,
    rr.region_revenue,
    rr.revenue_rank
FROM 
    RankedRegions rr
WHERE 
    rr.revenue_rank <= 5
ORDER BY 
    rr.region_revenue DESC;