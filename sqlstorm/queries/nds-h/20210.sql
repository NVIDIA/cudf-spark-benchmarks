WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
HighCostPart AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (ORDER BY p.p_retailprice DESC) AS rnk
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_container IS NOT NULL)
),

OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS OrderValue,
        COUNT(DISTINCT l.l_partkey) AS PartCount,
        MIN(l.l_shipdate) AS EarliestShipDate,
        MAX(l.l_shipdate) AS LatestShipDate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('F', 'O') AND 
        l.l_shipdate BETWEEN '1996-01-01' AND cast('1998-10-01' as date)
    GROUP BY 
        o.o_orderkey
)

SELECT 
    d.OrderValue,
    d.PartCount,
    COALESCE(s.s_name, 'Unknown Supplier') AS SupplierName,
    hp.p_name AS HighCostPartName,
    hp.p_retailprice AS HighCostPartPrice,
    CASE 
        WHEN d.OrderValue IS NULL THEN 'No Orders' 
        WHEN d.OrderValue > 10000 THEN 'High Value Order' 
        ELSE 'Low Value Order' 
    END AS OrderCategory,
    RANK() OVER (ORDER BY d.OrderValue DESC) AS ValueRank
FROM 
    OrderDetails d
LEFT JOIN 
    RankedSuppliers s ON s.rn = 1 AND s.TotalCost > 10000
LEFT JOIN 
    HighCostPart hp ON hp.rnk = 1
WHERE 
    d.PartCount >= (SELECT COUNT(*) FROM part) * 0.10
ORDER BY 
    d.OrderValue DESC NULLS LAST;