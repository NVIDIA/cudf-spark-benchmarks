WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
),

SupplierProfitability AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        (SUM(l.l_extendedprice * (1 - l.l_discount)) - SUM(ps.ps_supplycost * ps.ps_availqty)) AS profit
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),

TopProfitableSuppliers AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.profit,
        RANK() OVER (ORDER BY sp.profit DESC) AS profit_rank
    FROM 
        SupplierProfitability sp
    WHERE 
        sp.profit IS NOT NULL
)

SELECT 
    rp.p_name,
    rp.p_mfgr,
    rp.p_brand,
    rp.p_retailprice,
    COALESCE(tps.s_name, 'No Supplier') AS supplier_name,
    COALESCE(tps.profit, 0) AS supplier_profit
FROM 
    RankedParts rp
LEFT JOIN 
    TopProfitableSuppliers tps ON rp.p_partkey = tps.s_suppkey
WHERE 
    rp.rn <= 5
ORDER BY 
    rp.p_brand, rp.p_retailprice DESC;