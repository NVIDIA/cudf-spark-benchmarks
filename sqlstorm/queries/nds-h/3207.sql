WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        c.c_name,
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus IN ('F', 'O')
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
LineItemAggregates AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS line_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.c_name,
    l.total_revenue,
    s.total_supply_cost,
    r.o_totalprice,
    CASE 
        WHEN l.total_revenue IS NULL THEN 'No Revenue'
        ELSE 'Revenue Exists'
    END AS revenue_status
FROM 
    RankedOrders r
LEFT JOIN 
    LineItemAggregates l ON r.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierCost s ON l.line_count > 5 AND s.ps_partkey IN (
        SELECT DISTINCT ps.ps_partkey 
        FROM partsupp ps 
        JOIN supplier sup ON ps.ps_suppkey = sup.s_suppkey 
        WHERE sup.s_acctbal > 5000
    )
WHERE 
    r.rn = 1
ORDER BY 
    r.o_orderdate DESC,
    r.o_orderkey;