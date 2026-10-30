WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        p.p_comment
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%Steel%' OR 
        p.p_comment LIKE '%quality%'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        partsupp ps
    INNER JOIN 
        RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
    WHERE 
        rs.rn <= 3
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.p_brand,
    SUM(sp.ps_availqty) AS total_available_qty,
    AVG(sp.ps_supplycost) AS avg_supply_cost
FROM 
    FilteredParts fp
LEFT JOIN 
    SupplierParts sp ON fp.p_partkey = sp.ps_partkey
GROUP BY 
    fp.p_partkey, 
    fp.p_name, 
    fp.p_brand
HAVING 
    SUM(sp.ps_availqty) > 0
ORDER BY 
    avg_supply_cost DESC;
