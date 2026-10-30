WITH  RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) as price_rank
    FROM 
        part p
    WHERE p.p_size IS NOT NULL
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'No Balance' 
            WHEN s.s_acctbal < 0 THEN 'Debt'
            ELSE 'Positive Balance' 
        END AS acct_status
    FROM 
        supplier s
    WHERE 
        s.s_comment <> ''
),
NationCount AS (
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
    p.p_partkey, 
    p.p_name, 
    p.p_retailprice, 
    COALESCE(sd.acct_status, 'Unknown') AS supplier_status,
    nc.supplier_count
FROM 
    RankedParts p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
LEFT JOIN 
    NationCount nc ON sd.s_suppkey = nc.n_nationkey
WHERE 
    p.price_rank <= 5
    AND (sd.acct_status IS NOT NULL OR nc.supplier_count > 2)
ORDER BY 
    p.p_retailprice DESC, 
    sd.acct_status ASC,
    nc.supplier_count DESC
LIMIT 50 OFFSET 10;
