WITH  ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_by_price
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'Balance Unknown'
            ELSE 
                CASE 
                    WHEN s.s_acctbal < 1000 THEN 'Low Balance'
                    WHEN s.s_acctbal BETWEEN 1000 AND 5000 THEN 'Moderate Balance'
                    ELSE 'High Balance'
                END
        END AS balance_category
    FROM 
        supplier s 
    WHERE 
        s.s_comment NOT LIKE '%defective%'
),
order_totals AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
filtered_orders AS (
    SELECT 
        ot.o_orderkey,
        COUNT(DISTINCT ot.total_amount) AS unique_total_amounts
    FROM 
        order_totals ot
    WHERE 
        ot.total_amount > (SELECT AVG(total_amount) FROM order_totals)
    GROUP BY 
        ot.o_orderkey
)
SELECT 
    rp.p_name,
    rp.p_brand,
    sd.balance_category,
    fo.unique_total_amounts
FROM 
    ranked_parts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    supplier_details sd ON ps.ps_suppkey = sd.s_suppkey
LEFT JOIN 
    filtered_orders fo ON fo.o_orderkey = ps.ps_partkey
WHERE 
    rp.rank_by_price <= 10 AND 
    (sd.balance_category IS NOT NULL OR sd.balance_category = 'Balance Unknown')
ORDER BY 
    rp.p_retailprice DESC, sd.s_acctbal DESC
LIMIT 15 OFFSET 5;
