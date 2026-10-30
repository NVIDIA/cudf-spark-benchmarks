WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        DENSE_RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00
),
SupplierCount AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 2000.00
    GROUP BY 
        ps.ps_partkey
),
HighDemandParts AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N' 
        AND l.l_shipdate >= '1997-01-01'
    GROUP BY 
        l.l_partkey
    HAVING 
        SUM(l.l_quantity) > 500
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    sc.supplier_count,
    hdp.total_quantity
FROM 
    RankedParts rp
LEFT JOIN 
    SupplierCount sc ON rp.p_partkey = sc.ps_partkey
LEFT JOIN 
    HighDemandParts hdp ON rp.p_partkey = hdp.l_partkey
WHERE 
    rp.price_rank <= 3
ORDER BY 
    rp.p_brand, 
    rp.p_retailprice DESC;