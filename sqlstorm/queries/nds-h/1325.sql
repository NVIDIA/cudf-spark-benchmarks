WITH SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
NationRegionDetails AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_name
),
PartSupplierRanking AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS supply_rank
    FROM 
        partsupp ps
)
SELECT 
    psd.s_name AS supplier_name,
    psd.total_avail_qty,
    psd.total_supply_cost,
    cos.total_orders,
    cos.total_spent,
    nrd.region_name,
    nrd.supplier_count,
    psr.ps_partkey,
    psr.supply_rank
FROM 
    SupplierPartDetails psd
LEFT JOIN 
    CustomerOrderSummary cos ON psd.s_suppkey = cos.c_custkey
JOIN 
    PartSupplierRanking psr ON psd.s_suppkey = psr.ps_suppkey
JOIN 
    NationRegionDetails nrd ON psd.s_suppkey = nrd.n_nationkey
WHERE 
    psd.total_supply_cost > (
        SELECT AVG(total_supply_cost)
        FROM SupplierPartDetails
    )
    AND psd.total_avail_qty IS NOT NULL
ORDER BY 
    psd.total_supply_cost DESC, cos.total_spent ASC;
