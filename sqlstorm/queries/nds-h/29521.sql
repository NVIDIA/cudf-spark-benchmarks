WITH EnhancedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        CASE 
            WHEN LENGTH(p.p_comment) > 20 THEN CONCAT(SUBSTR(p.p_comment, 1, 20), '...')
            ELSE p.p_comment 
        END AS short_comment,
        r.r_name AS region_name,
        s.s_name AS supplier_name,
        s.s_acctbal AS supplier_account_balance
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS line_item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        SUM(l.l_tax) AS total_tax,
        o.o_orderdate,
        o.o_orderpriority
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderpriority
)
SELECT 
    ep.p_partkey, 
    ep.p_name, 
    ep.short_comment, 
    os.line_item_count, 
    os.total_revenue,
    os.total_tax,
    os.o_orderdate,
    os.o_orderpriority,
    ep.region_name,
    ep.supplier_name,
    ep.supplier_account_balance
FROM 
    EnhancedParts ep
JOIN 
    OrderStats os ON ep.p_partkey = os.o_orderkey 
WHERE 
    os.total_revenue > 10000
ORDER BY 
    os.total_revenue DESC, 
    ep.p_name ASC
LIMIT 50;
