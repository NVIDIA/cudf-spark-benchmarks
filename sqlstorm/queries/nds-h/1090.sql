
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
),
supplier_part_summary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
nation_supplier_counts AS (
    SELECT 
        n.n_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey
)
SELECT 
    r.r_name,
    p.p_name,
    COUNT(l.l_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
    COALESCE(ns.supplier_count, 0) AS total_suppliers,
    AVG(sps.avg_supply_cost) AS avg_cost_per_part
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    supplier_part_summary sps ON p.p_partkey = sps.ps_partkey
LEFT JOIN 
    nation_supplier_counts ns ON n.n_nationkey = ns.n_nationkey
WHERE 
    l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND (l.l_returnflag = 'N' OR l.l_returnflag IS NULL)
GROUP BY 
    r.r_name,
    p.p_name,
    ns.supplier_count,
    sps.avg_supply_cost
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 500000
ORDER BY 
    net_revenue DESC, 
    r.r_name,
    p.p_name;
