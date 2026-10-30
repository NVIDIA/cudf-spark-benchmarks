WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderInfo AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
NationSupplier AS (
    SELECT 
        n.n_name,
        SUM(ss.total_available) AS national_supply,
        SUM(os.total_revenue) AS national_revenue
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        SupplierStats ss ON s.s_suppkey = ss.s_suppkey
    LEFT JOIN 
        OrderInfo os ON s.s_suppkey = os.o_orderkey 
    GROUP BY 
        n.n_name
)
SELECT 
    ns.n_name,
    COALESCE(ns.national_supply, 0) AS national_supply,
    COALESCE(ns.national_revenue, 0) AS national_revenue,
    CASE 
        WHEN ns.national_supply > 0 THEN ns.national_revenue / ns.national_supply 
        ELSE NULL 
    END AS revenue_per_supply
FROM 
    NationSupplier ns
WHERE 
    ns.national_revenue IS NOT NULL
ORDER BY 
    revenue_per_supply DESC NULLS LAST
LIMIT 10;