WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F')
),
SupplierPricing AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        COALESCE(NULLIF(ps.ps_supplycost, 0), NULL) AS normalized_supplycost,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS rank_cost
    FROM 
        partsupp ps
),
CustomerRegionCTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_regionkey,
        SUM(o.o_totalprice) AS total_spent,
        CASE 
            WHEN SUM(o.o_totalprice) IS NULL THEN 'No Orders'
            WHEN SUM(o.o_totalprice) < 1000 THEN 'Low Spender'
            ELSE 'High Spender' 
        END AS spender_type
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        c.c_custkey, c.c_name, n.n_regionkey
),
PriceThreshold AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p1.p_retailprice) FROM part p1)
)
SELECT 
    cr.c_name,
    cr.total_spent,
    pr.p_name,
    CONCAT('Supplier ', s.s_suppkey, ' (', s.s_name, ') ') AS supplier_info,
    CASE 
        WHEN sp.normalized_supplycost IS NOT NULL THEN sp.normalized_supplycost * 1.05
        ELSE NULL 
    END AS adjusted_cost,
    CASE 
        WHEN cr.spender_type = 'High Spender' THEN 'Exemplary Customer'
        ELSE 'Regular Customer' 
    END AS customer_category
FROM 
    CustomerRegionCTE cr
JOIN 
    lineitem l ON cr.c_custkey = l.l_orderkey
JOIN 
    SupplierPricing sp ON l.l_partkey = sp.ps_partkey AND sp.rank_cost <= 3
LEFT JOIN 
    supplier s ON s.s_suppkey = sp.ps_suppkey
JOIN 
    PriceThreshold pr ON pr.p_partkey = l.l_partkey
WHERE 
    cr.total_spent IS NOT NULL 
    AND cr.n_regionkey NOT IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE '%Africa%')
ORDER BY 
    cr.total_spent DESC, adjusted_cost ASC
LIMIT 
    50;
