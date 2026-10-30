
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_inventory_value,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
TopRegions AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_regionkey, r.r_name
    HAVING 
        COUNT(DISTINCT s.s_suppkey) > 5
)
SELECT 
    rp.p_name,
    tr.r_name,
    tr.supplier_count,
    tr.total_supplier_balance,
    rp.total_inventory_value
FROM 
    RankedParts rp
JOIN 
    TopRegions tr ON tr.total_supplier_balance > 10000
JOIN 
    partsupp ps ON ps.ps_partkey = rp.p_partkey
JOIN 
    supplier s ON s.s_suppkey = ps.ps_suppkey
WHERE 
    rp.rank <= 10
ORDER BY 
    tr.total_supplier_balance DESC, rp.total_inventory_value DESC;
