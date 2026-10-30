WITH  ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_position
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
supplier_summary AS (
    SELECT 
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
lineitem_analysis AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS part_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate > DATE '1997-01-01' 
    GROUP BY 
        l.l_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(l.total_revenue, 0) AS total_revenue,
    CASE 
        WHEN r.r_name IS NULL THEN 'Unknown Region'
        ELSE r.r_name 
    END AS supplier_region,
    o.rank_position
FROM 
    part p
LEFT JOIN 
    supplier_summary ss ON p.p_partkey = ss.s_nationkey 
LEFT JOIN 
    lineitem_analysis l ON p.p_partkey = l.l_orderkey
LEFT JOIN 
    nation n ON n.n_nationkey = ss.s_nationkey 
LEFT JOIN 
    region r ON r.r_regionkey = n.n_regionkey
RIGHT JOIN 
    ranked_orders o ON o.o_orderkey = l.l_orderkey
WHERE 
    (p.p_size > 10 OR p.p_retailprice < 100.00) 
    AND o.rank_position <= 10
ORDER BY 
    total_revenue DESC, 
    total_supply_cost ASC;