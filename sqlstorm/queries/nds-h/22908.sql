
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_per_status
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
SupplierTotals AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_mfgr,
        p.p_type,
        p.p_retailprice,
        p.p_size,
        s.total_supply_cost,
        CASE 
            WHEN p.p_retailprice IS NOT NULL THEN p.p_retailprice - COALESCE(s.total_supply_cost, 0)
            ELSE NULL
        END AS profit_margin
    FROM 
        part p
    LEFT JOIN 
        SupplierTotals s ON p.p_partkey = s.ps_partkey
    WHERE 
        (p.p_size = 15 OR p.p_brand = 'Brand#23')
        AND (p.p_container LIKE '%Box%' OR p.p_comment IS NULL)
),
FrequentCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 5
)
SELECT 
    f.c_name,
    p.p_partkey AS p_partkey,
    p.p_mfgr AS p_mfgr,
    p.p_type AS p_type,
    p.p_retailprice AS p_retailprice,
    p.p_size AS p_size,
    p.total_supply_cost AS total_supply_cost,
    p.profit_margin,
    COALESCE(o.rank_per_status, 0) AS order_rank
FROM 
    FilteredParts p
JOIN 
    FrequentCustomers f ON p.p_partkey = f.c_custkey
LEFT JOIN 
    RankedOrders o ON o.o_orderkey = (SELECT MAX(o2.o_orderkey) FROM orders o2 WHERE o2.o_orderdate = CAST('1998-10-01' AS DATE))
WHERE 
    (p.profit_margin IS NOT NULL AND p.profit_margin < 100)
    OR (p.p_type IS NOT NULL AND p.p_type <> 'UNKNOWN')
ORDER BY 
    f.c_name ASC, p.profit_margin DESC;
