WITH supplier_balance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL OR s.s_acctbal < 0 THEN 'Negative or NULL Balance'
            ELSE 'Positive Balance'
        END AS balance_status
    FROM 
        supplier s
),
high_value_orders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
)
SELECT 
    p.p_name,
    p.p_brand,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity,
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    sb.balance_status
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation ns ON s.s_nationkey = ns.n_nationkey
LEFT JOIN 
    region r ON ns.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    high_value_orders hvo ON l.l_orderkey = hvo.o_orderkey
LEFT JOIN 
    supplier_balance sb ON s.s_suppkey = sb.s_suppkey
WHERE 
    p.p_retailprice IS NOT NULL 
    AND (p.p_size > 10 OR p.p_type LIKE '%metal%')
GROUP BY 
    p.p_name, p.p_brand, r.r_name, ns.n_name, sb.balance_status
HAVING 
    AVG(ps.ps_supplycost) > 50
ORDER BY 
    total_quantity DESC, avg_supply_cost ASC
LIMIT 100;
