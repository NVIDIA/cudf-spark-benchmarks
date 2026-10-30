WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        c.c_mktsegment,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT l.l_suppkey) AS supplier_count
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, c.c_mktsegment
),
SupplierPerformance AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_suppkey
),
FinalReport AS (
    SELECT 
        os.o_orderkey,
        os.c_mktsegment,
        os.revenue,
        sp.total_supply_cost,
        (os.revenue - sp.total_supply_cost) AS net_profit
    FROM 
        OrderSummary os
    LEFT JOIN 
        SupplierPerformance sp ON os.supplier_count = sp.ps_suppkey
    ORDER BY 
        net_profit DESC
)
SELECT 
    o.o_orderkey,
    o.c_mktsegment,
    o.revenue,
    o.total_supply_cost,
    o.net_profit
FROM 
    FinalReport o
WHERE 
    o.net_profit > 0
LIMIT 100;