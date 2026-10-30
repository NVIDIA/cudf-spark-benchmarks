WITH  supplier_parts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        p.p_partkey, 
        p.p_name, 
        ps.ps_availqty, 
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
), ranked_parts AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.p_partkey,
        sp.p_name,
        sp.ps_availqty,
        sp.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY sp.s_suppkey ORDER BY sp.ps_supplycost ASC) AS rank
    FROM 
        supplier_parts sp
), top_suppliers AS (
    SELECT 
        rp.s_suppkey,
        rp.s_name,
        SUM(rp.ps_supplycost * rp.ps_availqty) AS total_supply_cost
    FROM 
        ranked_parts rp
    WHERE 
        rp.rank <= 5
    GROUP BY 
        rp.s_suppkey, rp.s_name
)
SELECT 
    ns.n_name AS nation_name,
    COUNT(DISTINCT ts.s_suppkey) AS total_suppliers,
    SUM(ts.total_supply_cost) AS aggregate_supply_cost
FROM 
    nation ns
JOIN 
    supplier s ON ns.n_nationkey = s.s_nationkey
JOIN 
    top_suppliers ts ON ts.s_suppkey = s.s_suppkey
GROUP BY 
    ns.n_name
ORDER BY 
    total_suppliers DESC, aggregate_supply_cost DESC
LIMIT 10;
