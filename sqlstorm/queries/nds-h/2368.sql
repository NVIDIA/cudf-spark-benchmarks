WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_retailprice,
        DENSE_RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_price
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
SupplierAverages AS (
    SELECT 
        s.s_nationkey,
        AVG(s.s_acctbal) AS avg_acctbal,
        COUNT(s.s_suppkey) AS count_suppliers
    FROM 
        supplier s
    GROUP BY 
        s.s_nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        c.c_nationkey
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_totalprice > 10000
)
SELECT 
    COALESCE(rp.p_name, 'NA') AS part_name,
    COALESCE(na.n_name, 'Unknown') AS nation_name,
    COUNT(DISTINCT hvo.o_orderkey) AS high_value_order_count,
    SUM(rp.p_retailprice) AS total_retail_price,
    sa.avg_acctbal AS average_supplier_acct_bal
FROM 
    RankedParts rp
LEFT JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation na ON s.s_nationkey = na.n_nationkey
LEFT JOIN 
    HighValueOrders hvo ON hvo.c_nationkey = s.s_nationkey
JOIN 
    SupplierAverages sa ON na.n_nationkey = sa.s_nationkey
WHERE 
    rp.rank_price <= 5
GROUP BY 
    rp.p_name, na.n_name, sa.avg_acctbal
HAVING 
    COUNT(DISTINCT hvo.o_orderkey) > 0
ORDER BY 
    total_retail_price DESC;
