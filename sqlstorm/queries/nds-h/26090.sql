
WITH part_supplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_suppkey,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_size
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_name LIKE '%widget%'
),
nation_summary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
combined_summary AS (
    SELECT 
        ps.p_partkey,
        ps.p_name,
        ns.n_name AS nation,
        ns.supplier_count,
        ns.total_supply_cost,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.p_size) AS avg_part_size
    FROM 
        part_supplier ps
    JOIN 
        nation_summary ns ON ps.s_suppkey = ns.supplier_count
    GROUP BY 
        ps.p_partkey, ps.p_name, ns.n_name, ns.supplier_count, ns.total_supply_cost
)
SELECT 
    p.p_partkey,
    p.p_name,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    MAX(l.l_shipmode) AS max_ship_mode,
    MAX(LENGTH(p.p_comment)) AS max_comment_length
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    combined_summary cs ON p.p_partkey = cs.p_partkey
WHERE 
    p.p_retailprice > 100
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    revenue DESC
LIMIT 10;
