WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        COALESCE(sc.avg_supplycost, 0) AS avg_supplycost,
        p.p_retailprice,
        (p.p_retailprice - COALESCE(sc.avg_supplycost, 0)) AS price_difference
    FROM 
        part p
    LEFT JOIN 
        SupplierCosts sc ON p.p_partkey = sc.ps_partkey
)
SELECT 
    po.o_orderkey,
    po.o_orderdate,
    po.o_totalprice,
    po.c_name,
    pd.p_name,
    pd.price_difference,
    CASE 
        WHEN pd.price_difference > 0 THEN 'Profit Potential'
        WHEN pd.price_difference = 0 THEN 'Even Margin'
        ELSE 'Loss Potential' 
    END AS pricing_status
FROM 
    RankedOrders po
JOIN 
    lineitem li ON po.o_orderkey = li.l_orderkey
JOIN 
    PartDetails pd ON li.l_partkey = pd.p_partkey
WHERE 
    po.rn <= 5 AND 
    pd.price_difference IS NOT NULL
ORDER BY 
    po.o_orderdate DESC, 
    po.o_totalprice DESC;