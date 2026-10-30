WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
HighCostParts AS (
    SELECT 
        p_partkey, 
        p_name, 
        total_cost 
    FROM 
        RankedParts 
    WHERE 
        rank = 1
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    hp.p_name,
    hp.total_cost,
    sd.s_name,
    sd.nation_name,
    sd.s_acctbal
FROM 
    HighCostParts hp
LEFT JOIN 
    SupplierDetails sd ON sd.rank <= 5
WHERE 
    (hp.total_cost IS NOT NULL AND sd.s_acctbal IS NULL)
    OR (hp.total_cost IS NULL AND sd.s_acctbal > 1000)
ORDER BY 
    hp.total_cost DESC, sd.s_acctbal DESC;
