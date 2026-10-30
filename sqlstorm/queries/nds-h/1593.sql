WITH SupplyStats AS (
    SELECT 
        ps_partkey,
        SUM(ps_supplycost) AS total_supplycost,
        AVG(ps_availqty) AS avg_availability
    FROM 
        partsupp
    GROUP BY 
        ps_partkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate <= DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey
),
PartRegions AS (
    SELECT 
        p.p_partkey,
        r.r_name
    FROM 
        part p
    LEFT JOIN 
        supplier s ON p.p_partkey = s.s_suppkey
    LEFT JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    pr.p_partkey,
    pr.r_name,
    ss.total_supplycost,
    ss.avg_availability,
    od.total_revenue,
    od.unique_customers
FROM 
    PartRegions pr
LEFT JOIN 
    SupplyStats ss ON pr.p_partkey = ss.ps_partkey
LEFT JOIN 
    OrderDetails od ON ss.ps_partkey = od.o_orderkey
WHERE 
    (ss.total_supplycost IS NOT NULL AND ss.avg_availability > 100) OR 
    (od.total_revenue IS NOT NULL AND od.unique_customers > 50)
ORDER BY 
    pr.r_name, ss.total_supplycost DESC;