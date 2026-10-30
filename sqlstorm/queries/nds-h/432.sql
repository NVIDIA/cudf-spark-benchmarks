
WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_supply_cost,
        ss.part_count,
        RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS rank
    FROM 
        SupplierSummary ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.total_supply_cost > (
            SELECT AVG(total_supply_cost) FROM SupplierSummary
        )
),
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_linenumber) AS item_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1996-01-01' AND l.l_shipdate < '1997-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    hs.s_name,
    hs.total_supply_cost,
    hs.part_count,
    la.total_revenue,
    la.item_count,
    RANK() OVER (PARTITION BY hs.s_suppkey ORDER BY la.total_revenue DESC) AS revenue_rank
FROM 
    HighValueSuppliers hs
LEFT JOIN 
    LineItemAnalysis la ON hs.s_suppkey = (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        JOIN 
            lineitem l ON ps.ps_partkey = l.l_partkey 
        WHERE 
            l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F')
        LIMIT 1
    )
WHERE 
    hs.rank <= 10
ORDER BY 
    hs.total_supply_cost DESC, la.total_revenue DESC;
