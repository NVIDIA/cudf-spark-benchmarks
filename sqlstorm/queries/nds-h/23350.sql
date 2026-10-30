
WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT 
                        p2.p_size 
                     FROM 
                        part p2 
                     WHERE 
                        p2.p_retailprice > 100 AND 
                        p2.p_type LIKE '%gold%')
),
supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        (CASE 
            WHEN s.s_acctbal IS NULL THEN 'Unknown' 
            ELSE 'Known' 
         END) AS account_status
    FROM 
        supplier s
    WHERE 
        s.s_nationkey IN (SELECT n.n_nationkey 
                          FROM nation n 
                          WHERE n.n_comment IS NOT NULL)
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(DISTINCT li.l_linenumber) AS item_count,
        MAX(li.l_shipdate) AS last_ship_date
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    r.p_partkey, 
    r.p_name, 
    r.p_retailprice, 
    COALESCE(s.s_suppkey, -1) AS supplier_key,
    s.account_status,
    o.o_orderkey,
    o.total_revenue,
    CASE 
        WHEN o.last_ship_date < DATE '1998-10-01' - INTERVAL '30 days' THEN 'Old Shipment' 
        ELSE 'Recent Shipment' 
    END AS shipment_status
FROM 
    ranked_parts r
LEFT JOIN 
    partsupp ps ON r.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier_info s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    order_summary o ON r.p_partkey = o.o_orderkey
WHERE 
    r.rn <= 5 
    AND (s.s_acctbal IS NOT NULL OR s.s_acctbal IS NULL)
ORDER BY 
    r.p_retailprice ASC, 
    o.total_revenue DESC 
LIMIT 100;
