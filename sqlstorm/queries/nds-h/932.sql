
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
),
supplier_part AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, p.p_name, p.p_brand
),
nation_supplier AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name,
    ns.n_name,
    COALESCE(sp.total_available_qty, 0) AS available_qty,
    COALESCE(sp.total_supply_cost, 0) AS total_supply_value,
    ro.o_orderdate,
    ro.o_totalprice,
    CASE 
        WHEN ro.o_orderkey IS NOT NULL THEN 'Has Orders' 
        ELSE 'No Orders' 
    END AS order_status
FROM 
    region r
LEFT JOIN 
    nation_supplier ns ON ns.n_nationkey = r.r_regionkey
LEFT JOIN 
    supplier_part sp ON sp.ps_suppkey = ns.supplier_count
LEFT JOIN 
    ranked_orders ro ON ro.o_orderkey = sp.ps_partkey
WHERE 
    r.r_name LIKE 'S%'
    AND (sp.total_available_qty IS NULL OR sp.total_available_qty > 100)
ORDER BY 
    r.r_name, ns.n_name, ro.o_totalprice DESC;
