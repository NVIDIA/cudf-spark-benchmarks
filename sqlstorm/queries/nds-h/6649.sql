WITH RankedSupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        p.p_name AS part_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 0
),
AggregatedData AS (
    SELECT 
        rs.nation_name,
        SUM(rs.ps_availqty) AS total_avail_qty,
        AVG(rs.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT rs.s_suppkey) AS unique_suppliers
    FROM 
        RankedSupplier rs
    WHERE 
        rs.rank = 1
    GROUP BY 
        rs.nation_name
)
SELECT 
    ad.nation_name,
    ad.total_avail_qty,
    ad.avg_supply_cost,
    ad.unique_suppliers
FROM 
    AggregatedData ad
WHERE 
    ad.total_avail_qty > 1000
ORDER BY 
    ad.avg_supply_cost DESC;
