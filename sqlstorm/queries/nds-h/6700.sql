WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_mktsegment,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-10-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_mktsegment
),
TopSegments AS (
    SELECT 
        c_mktsegment,
        SUM(total_revenue) AS segment_revenue
    FROM 
        RankedOrders
    WHERE 
        rnk <= 10
    GROUP BY 
        c_mktsegment
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    ts.c_mktsegment,
    ts.segment_revenue
FROM 
    TopSegments ts
JOIN 
    nation n ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps JOIN part p ON ps.ps_partkey = p.p_partkey LIMIT 1))
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
ORDER BY 
    ts.segment_revenue DESC;