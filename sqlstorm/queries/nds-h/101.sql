WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierPerformance AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 1000
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
TopSuppliers AS (
    SELECT 
        sp.ps_partkey,
        sp.ps_suppkey,
        sp.total_avail_quantity,
        sp.avg_supply_cost,
        RANK() OVER (PARTITION BY sp.ps_partkey ORDER BY sp.total_avail_quantity DESC) AS rank
    FROM 
        SupplierPerformance sp
),
RevenueByPart AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_part_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
    GROUP BY 
        l.l_partkey
)

SELECT 
    p.p_name,
    p.p_size,
    COALESCE(rbp.total_part_revenue, 0) AS total_part_revenue,
    COALESCE(ts.total_avail_quantity, 0) AS total_avail_quantity,
    COALESCE(ts.avg_supply_cost, 0) AS avg_supply_cost,
    CASE 
        WHEN COALESCE(ts.total_avail_quantity, 0) > 0 
        THEN (COALESCE(rbp.total_part_revenue, 0) / COALESCE(ts.total_avail_quantity, 1))
        ELSE 0
    END AS revenue_per_quantity
FROM 
    part p
LEFT JOIN 
    RevenueByPart rbp ON p.p_partkey = rbp.l_partkey
LEFT JOIN 
    TopSuppliers ts ON p.p_partkey = ts.ps_partkey AND ts.rank = 1
WHERE 
    p.p_retailprice IS NOT NULL
ORDER BY 
    revenue_per_quantity DESC;