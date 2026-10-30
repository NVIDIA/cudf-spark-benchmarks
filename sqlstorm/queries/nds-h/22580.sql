WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        DENSE_RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 5 AND 20 AND 
        (p.p_comment IS NULL OR p.p_comment LIKE '%urgent%')
),
SupplierCounts AS (
    SELECT 
        ps.ps_partkey, 
        COUNT(*) AS supplier_count 
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
OrderStats AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        o.o_orderkey
),
CustomerInsights AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS customer_spending,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus <> 'C'
    GROUP BY 
        c.c_custkey
)
SELECT 
    R.p_partkey, 
    R.p_name, 
    R.p_retailprice,
    S.supplier_count,
    C.customer_spending,
    CASE 
        WHEN C.spending_rank IS NULL THEN 'No Orders'
        WHEN C.customer_spending < 1000 THEN 'Low Spender'
        ELSE 'High Spender'
    END AS spending_category
FROM 
    RankedParts R
LEFT JOIN 
    SupplierCounts S ON R.p_partkey = S.ps_partkey
LEFT JOIN 
    CustomerInsights C ON R.p_partkey = C.c_custkey
WHERE 
    R.price_rank <= 5 
    OR (R.price_rank IS NULL AND R.p_retailprice IS NOT NULL)
ORDER BY 
    R.p_retailprice DESC NULLS LAST;