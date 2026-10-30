WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
OrderSummary AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
        AND o.o_orderstatus IN ('O', 'F', 'P')
    GROUP BY 
        o.o_custkey
),
SupplierPerformance AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.part_count,
        ss.total_supply_cost,
        ROUND(ss.total_supply_cost / NULLIF(ss.part_count, 0), 2) AS avg_cost_per_part,
        (SELECT AVG(total_spent) FROM OrderSummary) AS avg_order_spent
    FROM 
        SupplierStats ss
    WHERE 
        ss.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
)
SELECT 
    sp.s_name,
    sp.part_count,
    sp.total_supply_cost,
    sp.avg_cost_per_part,
    os.total_spent AS customer_total_spent,
    os.order_count
FROM 
    SupplierPerformance sp
FULL OUTER JOIN 
    OrderSummary os ON sp.s_suppkey = os.o_custkey
WHERE 
    (sp.avg_cost_per_part IS NOT NULL OR os.total_spent IS NOT NULL)
    AND (sp.part_count > 5 OR os.order_count > 2)
ORDER BY 
    sp.s_name ASC, os.total_spent DESC;