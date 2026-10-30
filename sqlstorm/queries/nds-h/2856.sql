WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' - INTERVAL '90 days'
        AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
AggregatedData AS (
    SELECT 
        rp.o_orderkey,
        sp.p_partkey,
        sp.p_name,
        COALESCE(SUM(sp.ps_supplycost), 0) AS supply_cost,
        RANK() OVER (PARTITION BY rp.o_orderkey ORDER BY COALESCE(SUM(sp.ps_supplycost), 0) DESC) AS part_rank
    FROM 
        RankedOrders rp
    LEFT JOIN 
        SupplierParts sp ON rp.o_orderkey = sp.s_suppkey
    GROUP BY 
        rp.o_orderkey, sp.p_partkey, sp.p_name
)
SELECT 
    a.o_orderkey,
    a.p_partkey,
    a.p_name,
    a.supply_cost,
    COALESCE(ROW_NUMBER() OVER (PARTITION BY a.o_orderkey ORDER BY a.supply_cost DESC), 0) AS supply_cost_rank
FROM 
    AggregatedData a
WHERE 
    a.supply_cost > (
        SELECT AVG(supply_cost)
        FROM AggregatedData
        WHERE p_partkey IS NOT NULL
    )
ORDER BY 
    a.o_orderkey, a.supply_cost DESC;