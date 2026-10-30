WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierRanked AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(ps.ps_partkey) AS supply_count,
        RANK() OVER (ORDER BY COUNT(ps.ps_partkey) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    o.o_orderkey, 
    o.o_orderdate, 
    r.total_revenue, 
    s.s_name, 
    s.supply_count
FROM 
    RankedOrders r
JOIN 
    orders o ON r.o_orderkey = o.o_orderkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    SupplierRanked s ON l.l_suppkey = s.s_suppkey
WHERE 
    r.revenue_rank <= 5 AND s.supplier_rank <= 10
ORDER BY 
    r.total_revenue DESC, 
    s.supply_count DESC;