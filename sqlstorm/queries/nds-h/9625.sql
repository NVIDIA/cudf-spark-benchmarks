WITH RegionalSales AS (
    SELECT 
        r.r_name AS region,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
        AND o.o_orderdate < '1997-12-31'
        AND l.l_shipmode IN ('TRUCK', 'SHIP')
    GROUP BY 
        r.r_name
),
CustomerSegments AS (
    SELECT 
        c.c_mktsegment,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_mktsegment
)
SELECT 
    rs.region,
    rs.total_sales,
    cs.c_mktsegment,
    cs.total_revenue
FROM 
    RegionalSales rs
JOIN 
    CustomerSegments cs ON cs.total_revenue > 100000
ORDER BY 
    rs.total_sales DESC,
    cs.total_revenue DESC;