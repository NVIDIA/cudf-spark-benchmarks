WITH RankedSuppliers AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS supplier_rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
), 
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type
),
TopParts AS (
    SELECT 
        pd.*,
        ROW_NUMBER() OVER (ORDER BY pd.total_supply_cost DESC) AS part_rank
    FROM 
        PartDetails pd
    WHERE 
        pd.num_suppliers > 5
)
SELECT 
    tp.p_partkey,
    tp.p_name,
    tp.p_mfgr,
    tp.p_brand,
    tp.p_type,
    tp.total_available_quantity,
    tp.total_supply_cost,
    ARRAY_AGG(rs.s_name) AS top_suppliers
FROM 
    TopParts tp
JOIN 
    RankedSuppliers rs ON tp.p_partkey = rs.ps_partkey AND rs.supplier_rank <= 3
WHERE 
    tp.part_rank <= 10
GROUP BY 
    tp.p_partkey, tp.p_name, tp.p_mfgr, tp.p_brand, tp.p_type, tp.total_available_quantity, tp.total_supply_cost
ORDER BY 
    tp.total_supply_cost DESC;
