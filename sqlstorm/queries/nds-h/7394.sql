WITH TotalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        n.n_name
),
SupplierStatistics AS (
    SELECT 
        s.s_name AS supplier_name,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
),
PartMetrics AS (
    SELECT 
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_name
)
SELECT 
    ts.nation_name,
    ts.total_revenue,
    ss.supplier_name,
    ss.supplied_parts,
    ss.total_supply_cost,
    pm.p_name,
    pm.supplier_count,
    pm.avg_supply_cost
FROM 
    TotalSales ts
JOIN 
    SupplierStatistics ss ON ts.nation_name = ss.supplier_name
JOIN 
    PartMetrics pm ON ss.supplier_name = pm.p_name
ORDER BY 
    ts.total_revenue DESC, ss.total_supply_cost DESC, pm.supplier_count DESC
LIMIT 10;