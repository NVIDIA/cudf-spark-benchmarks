WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1994-01-01' AND l.l_shipdate < DATE '1994-01-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRevenueOrders AS (
    SELECT 
        r.o_orderkey,
        r.total_revenue
    FROM 
        RankedOrders r
    WHERE 
        r.revenue_rank <= 10
)
SELECT 
    p.p_mfgr,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(s.s_acctbal) AS avg_supplier_acctbal,
    SUM(t.total_revenue) AS total_revenue
FROM 
    partsupp ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    TopRevenueOrders t ON t.o_orderkey = ps.ps_partkey
GROUP BY 
    p.p_mfgr
ORDER BY 
    total_revenue DESC;
