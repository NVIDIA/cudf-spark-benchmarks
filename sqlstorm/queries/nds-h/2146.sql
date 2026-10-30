WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierPartStats AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey
),
HighRevenueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.total_revenue,
        RANK() OVER (ORDER BY ro.total_revenue DESC) AS revenue_rank
    FROM 
        RankedOrders ro
    WHERE 
        ro.total_revenue > 10000
)
SELECT 
    n.n_name,
    p.p_name,
    s.s_name,
    COALESCE(sp.total_avail_qty, 0) AS available_quantity,
    COALESCE(sp.avg_supply_cost, 0.00) AS average_cost,
    hro.total_revenue
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    HighRevenueOrders hro ON hro.o_orderkey = ps.ps_partkey 
LEFT JOIN 
    SupplierPartStats sp ON p.p_partkey = sp.ps_partkey AND s.s_suppkey = sp.s_suppkey
WHERE 
    n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'Asia')
    AND (sp.total_avail_qty IS NOT NULL OR hro.total_revenue IS NOT NULL)
ORDER BY 
    hro.total_revenue DESC NULLS LAST, 
    n.n_name, 
    p.p_name;