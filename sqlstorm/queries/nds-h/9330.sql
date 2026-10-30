WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),

BestSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
)

SELECT 
    rp.p_name,
    rp.p_brand,
    bs.s_name AS supplier_name,
    bs.nation_name,
    rp.total_supply_cost
FROM 
    RankedParts rp
JOIN 
    BestSuppliers bs ON rp.p_brand = bs.nation_name
WHERE 
    rp.rank <= 3 AND bs.supplier_rank <= 5
ORDER BY 
    rp.total_supply_cost DESC, 
    bs.s_acctbal DESC
LIMIT 10;
