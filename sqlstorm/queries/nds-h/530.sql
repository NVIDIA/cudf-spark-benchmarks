WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
CustomerSummary AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_nationkey
),
FinalResult AS (
    SELECT 
        r.r_name,
        cs.order_count,
        cs.total_spent,
        COALESCE(hvs.total_supply_cost, 0) AS total_supply_cost
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        CustomerSummary cs ON n.n_nationkey = cs.c_nationkey
    LEFT JOIN 
        HighValueSuppliers hvs ON hvs.s_suppkey IN (
            SELECT ps.ps_suppkey 
            FROM partsupp ps 
            JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
            WHERE l.l_orderkey IN (SELECT o_orderkey FROM RankedOrders WHERE rn <= 5)
        )
)
SELECT 
    f.r_name,
    f.order_count,
    f.total_spent,
    f.total_supply_cost,
    CASE 
        WHEN f.total_supply_cost IS NULL THEN 'No Supply Cost'
        WHEN f.total_supply_cost > 5000 THEN 'High Supply Cost'
        ELSE 'Normal Supply Cost'
    END AS supply_cost_category
FROM 
    FinalResult f
ORDER BY 
    f.total_spent DESC;