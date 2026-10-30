WITH rated_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
), 
high_value_parts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_retailprice,
        rp.total_supply_cost,
        rp.supplier_count
    FROM 
        rated_parts rp
    WHERE 
        rp.total_supply_cost > 10000
), 
nation_supplier_counts AS (
    SELECT 
        n.n_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey
)

SELECT 
    hp.p_partkey,
    hp.p_name,
    hp.p_brand,
    hp.p_retailprice,
    n.n_name AS nation_name,
    nsc.total_suppliers
FROM 
    high_value_parts hp
JOIN 
    partsupp ps ON hp.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    nation_supplier_counts nsc ON n.n_nationkey = nsc.n_nationkey
WHERE 
    hp.supplier_count > 5
ORDER BY 
    hp.total_supply_cost DESC
LIMIT 10;
