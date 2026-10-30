WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank_totalprice
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_orderdate >= DATE '1997-01-01'
),
supply_info AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS total_suppliers,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
lineitem_summary AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        AVG(l.l_quantity) AS avg_quantity,
        COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS return_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(ls.net_revenue, 0) AS net_revenue,
    ls.avg_quantity,
    COALESCE(si.total_suppliers, 0) AS total_suppliers,
    si.total_supply_value,
    ro.o_orderdate,
    ro.rank_totalprice
FROM 
    part p
LEFT JOIN 
    lineitem_summary ls ON p.p_partkey = ls.l_partkey
LEFT JOIN 
    supply_info si ON p.p_partkey = si.ps_partkey
LEFT JOIN 
    ranked_orders ro ON ro.rank_totalprice <= 5
WHERE 
    p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_mfgr = p.p_mfgr
    ) 
    AND (p.p_size IS NULL OR p.p_size > 10)
ORDER BY 
    net_revenue DESC,
    p.p_name;