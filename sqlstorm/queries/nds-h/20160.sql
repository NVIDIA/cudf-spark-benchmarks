
WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
), 
region_nation AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        n.n_nationkey,
        n.n_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY n.n_name) AS nation_rank
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    COALESCE(rn.n_name, 'Unknown Nation') AS nation_name,
    SUM(CASE 
            WHEN l.l_returnflag = 'R' THEN l.l_discount * l.l_extendedprice 
            ELSE 0 
        END) AS total_return_discount,
    MAX(l.l_extendedprice) AS max_price_with_tax,
    COUNT(DISTINCT CASE WHEN l.l_shipmode LIKE 'AIR%' THEN l.l_orderkey END) AS air_shipped_orders,
    COUNT(*) AS fulfilled_orders_count
FROM 
    ranked_parts rp
LEFT JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey 
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
LEFT JOIN 
    lineitem l ON l.l_partkey = rp.p_partkey 
LEFT JOIN 
    orders o ON o.o_orderkey = l.l_orderkey 
JOIN 
    region_nation rn ON s.s_nationkey = rn.n_nationkey 
WHERE 
    rp.price_rank <= 10 
    AND (l.l_returnflag IS NULL OR l.l_returnflag IN ('R', 'N')) 
    AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL) 
    AND rn.nation_rank = 1 
GROUP BY 
    rp.p_partkey, rp.p_name, rp.p_brand, rn.n_name
ORDER BY 
    total_return_discount DESC, max_price_with_tax ASC
LIMIT 100;
