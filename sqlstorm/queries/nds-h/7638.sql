WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand
), TopParts AS (
    SELECT 
        *, 
        ROW_NUMBER() OVER (ORDER BY total_supply_cost DESC) AS rnk
    FROM 
        RankedParts
), SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
)

SELECT 
    tp.p_name,
    tp.p_brand,
    si.s_name AS supplier_name,
    si.nation_name,
    tp.total_supply_cost,
    si.total_available_qty
FROM 
    TopParts tp
JOIN 
    SupplierInfo si ON tp.p_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_suppkey IN (
            SELECT DISTINCT s.s_suppkey 
            FROM supplier s
            JOIN nation n ON s.s_nationkey = n.n_nationkey
            WHERE n.n_name = 'USA'
        )
    )
WHERE 
    tp.rnk <= 10
ORDER BY 
    tp.total_supply_cost DESC, 
    si.total_available_qty DESC;
