
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus IN ('F', 'O')
), SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS TotalAvailableQty,
        COUNT(DISTINCT ps.ps_partkey) AS UniqueParts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), LineItemAggregate AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalNetRevenue,
        COUNT(*) AS LineItemCount
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
), OrderRevenueExt AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        COALESCE(r.TotalNetRevenue, 0) AS TotalRevenue,
        ROW_NUMBER() OVER (ORDER BY COALESCE(r.TotalNetRevenue, 0) DESC) AS RevenueRank
    FROM 
        RankedOrders o
    LEFT JOIN 
        LineItemAggregate r ON o.o_orderkey = r.l_orderkey
), CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS TotalSpent,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 MONTH'
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name,
    s.TotalAvailableQty,
    COALESCE(o.TotalRevenue, 0) AS TotalRevenue,
    cp.TotalSpent AS CustomerTotalSpent,
    CASE 
        WHEN cp.TotalSpent > 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS CustomerCategory
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierInfo s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    OrderRevenueExt o ON ps.ps_partkey = o.o_orderkey
LEFT JOIN 
    CustomerPurchases cp ON o.o_orderkey = cp.c_custkey
WHERE 
    p.p_retailprice IS NOT NULL
    AND (s.TotalAvailableQty > 0 OR o.TotalRevenue > 0)
ORDER BY 
    CustomerCategory, TotalRevenue DESC, s.TotalAvailableQty ASC;
