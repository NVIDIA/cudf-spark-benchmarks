WITH SupplierPartPricing AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        (ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
),
RankedPricing AS (
    SELECT 
        spp.s_suppkey,
        spp.s_name,
        spp.p_partkey,
        spp.p_name,
        spp.ps_supplycost,
        spp.ps_availqty,
        spp.total_value,
        RANK() OVER (PARTITION BY spp.p_partkey ORDER BY spp.total_value DESC) AS rank_value
    FROM 
        SupplierPartPricing spp
)
SELECT 
    rp.s_suppkey,
    rp.s_name,
    rp.p_partkey,
    rp.p_name,
    rp.ps_supplycost,
    rp.ps_availqty,
    rp.total_value
FROM 
    RankedPricing rp
WHERE 
    rp.rank_value = 1
ORDER BY 
    rp.p_partkey, 
    rp.total_value DESC;
