WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
),
SupplierPartStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
NullHandlingExample AS (
    SELECT 
        p.p_partkey,
        COUNT(l.l_orderkey) AS order_count,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    p.p_name,
    p.p_brand,
    r.r_name AS supplier_region,
    s.s_name,
    COALESCE(o.total_revenue, 0) AS total_revenue_last_year,
    ss.total_avail_qty,
    ss.avg_supply_cost
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    NullHandlingExample o ON p.p_partkey = o.p_partkey
JOIN 
    SupplierPartStats ss ON p.p_partkey = ss.ps_partkey
WHERE 
    p.p_size > 10 
    AND ss.avg_supply_cost > (
        SELECT AVG(ss2.avg_supply_cost) 
        FROM SupplierPartStats ss2
        WHERE ss2.total_avail_qty < 100
    )
ORDER BY 
    total_revenue_last_year DESC, 
    p.p_name ASC;