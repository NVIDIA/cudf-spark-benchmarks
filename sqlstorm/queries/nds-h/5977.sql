WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        c.c_mktsegment,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER(PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name, c.c_mktsegment
),
TopSegments AS (
    SELECT 
        c_mktsegment,
        AVG(total_revenue) AS avg_revenue
    FROM 
        RankedOrders
    WHERE 
        revenue_rank <= 10
    GROUP BY 
        c_mktsegment
)
SELECT 
    ts.c_mktsegment,
    ts.avg_revenue,
    r.r_name,
    COUNT(DISTINCT s.s_suppkey) AS distinct_suppliers,
    AVG(s.s_acctbal) AS avg_supplier_balance
FROM 
    TopSegments ts
JOIN 
    nation n ON ts.c_mktsegment = n.n_name
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
GROUP BY 
    ts.c_mktsegment, ts.avg_revenue, r.r_name
ORDER BY 
    ts.avg_revenue DESC;