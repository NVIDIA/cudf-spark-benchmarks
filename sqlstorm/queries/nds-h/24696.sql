
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_TIMESTAMP - INTERVAL '6 months'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(NULLIF(s.s_comment, ''), 'No comments') AS sanitized_comment,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_within_nation
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 10000
),
AvailableParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        part p 
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_availqty) > 50
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey, 
        ro.o_totalprice,
        CASE 
            WHEN ro.o_totalprice BETWEEN 500 AND 1000 THEN 'Medium Value'
            WHEN ro.o_totalprice > 1000 THEN 'High Value'
            ELSE 'Low Value'
        END AS value_category
    FROM 
        RankedOrders ro
    WHERE 
        ro.rn <= 10
)
SELECT 
    hp.o_orderkey, 
    hp.o_totalprice, 
    hp.value_category,
    COALESCE(sd.s_name, 'Unknown Supplier') AS supplier_name,
    ap.p_name,
    ap.total_available
FROM 
    HighValueOrders hp
LEFT JOIN 
    lineitem li ON hp.o_orderkey = li.l_orderkey
LEFT JOIN 
    supplier s ON li.l_suppkey = s.s_suppkey
LEFT JOIN 
    AvailableParts ap ON li.l_partkey = ap.p_partkey
LEFT JOIN 
    SupplierDetails sd ON s.s_suppkey = sd.s_suppkey AND sd.rank_within_nation = 1
WHERE 
    hp.value_category = 'High Value' 
    AND ap.total_available IS NOT NULL
ORDER BY 
    hp.o_totalprice DESC, 
    supplier_name ASC;
