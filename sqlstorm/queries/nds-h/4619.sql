WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1996-01-01' 
        AND o.o_orderdate < '1997-01-01'
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueOrders AS (
    SELECT 
        r.r_name,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS revenue
    FROM 
        lineitem lo
    JOIN 
        orders o ON lo.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        lo.l_shipdate >= '1996-01-01' 
        AND lo.l_shipdate < '1997-01-01'
    GROUP BY 
        r.r_name
),
FinalReport AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        so.total_avail_qty,
        so.avg_supply_cost,
        hvo.revenue,
        RANK() OVER (ORDER BY hvo.revenue DESC) AS revenue_rank
    FROM 
        RankedOrders o
    LEFT JOIN 
        SupplierSummary so ON o.o_orderkey = so.s_suppkey
    LEFT JOIN 
        HighValueOrders hvo ON so.total_avail_qty IS NOT NULL
    WHERE 
        o.order_rank <= 10
)

SELECT 
    fr.o_orderkey,
    fr.o_orderdate,
    COALESCE(fr.total_avail_qty, 0) AS total_avail_qty,
    COALESCE(fr.avg_supply_cost, 0) AS avg_supply_cost,
    COALESCE(fr.revenue, 0) AS total_revenue
FROM 
    FinalReport fr
ORDER BY 
    fr.o_orderdate DESC;