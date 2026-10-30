
WITH RankedProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_price
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%metal%' 
        OR p.p_comment LIKE '%metal%'
),
SuppliersWithComments AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_comment,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_comment LIKE '%reliable%'
),
CombinedData AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_retailprice,
        swc.s_suppkey,
        swc.s_name,
        swc.nation_name,
        rp.rank_price
    FROM 
        RankedProducts rp
    LEFT JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    LEFT JOIN 
        SuppliersWithComments swc ON ps.ps_suppkey = swc.s_suppkey
),
FinalSelection AS (
    SELECT 
        cd.p_partkey,
        cd.p_name,
        cd.p_brand,
        cd.p_retailprice,
        cd.s_name,
        cd.nation_name,
        CASE 
            WHEN cd.p_retailprice > 500 THEN 'Expensive'
            WHEN cd.p_retailprice BETWEEN 250 AND 500 THEN 'Moderately Priced'
            ELSE 'Affordable'
        END AS price_category
    FROM 
        CombinedData cd
    WHERE 
        cd.rank_price <= 5 
)
SELECT 
    f.p_partkey,
    f.p_name,
    f.p_brand,
    f.p_retailprice,
    f.s_name,
    f.nation_name,
    f.price_category
FROM 
    FinalSelection f
ORDER BY 
    f.p_brand, f.p_retailprice DESC;
