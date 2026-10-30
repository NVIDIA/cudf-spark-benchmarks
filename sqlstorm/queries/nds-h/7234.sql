WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name, r.r_name
),
OrderSummary AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
    GROUP BY 
        o.o_custkey
)
SELECT 
    d.s_suppkey,
    d.s_name,
    d.nation_name,
    d.region_name,
    d.part_count,
    d.total_supply_cost,
    o.total_revenue,
    o.total_orders
FROM 
    SupplierDetails d
LEFT JOIN 
    OrderSummary o ON d.s_suppkey = o.o_custkey
WHERE 
    d.total_supply_cost > 10000
ORDER BY 
    d.total_supply_cost DESC,
    o.total_revenue DESC
LIMIT 50;