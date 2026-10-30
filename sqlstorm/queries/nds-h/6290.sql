WITH SupplierParts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        p.p_partkey, 
        p.p_name, 
        ps.ps_availqty, 
        ps.ps_supplycost,
        ps.ps_availqty * ps.ps_supplycost AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
AggregatedData AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(sp.total_cost) AS total_supply_cost,
        COUNT(DISTINCT sp.s_suppkey) AS supplier_count
    FROM 
        SupplierParts sp
    JOIN 
        supplier s ON sp.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_name, r.r_name
),
RankedSuppliers AS (
    SELECT 
        nation_name,
        region_name,
        total_supply_cost,
        supplier_count,
        RANK() OVER (PARTITION BY region_name ORDER BY total_supply_cost DESC) AS cost_rank
    FROM 
        AggregatedData
)
SELECT 
    nation_name,
    region_name,
    total_supply_cost,
    supplier_count
FROM 
    RankedSuppliers
WHERE 
    cost_rank <= 3
ORDER BY 
    region_name, total_supply_cost DESC;
