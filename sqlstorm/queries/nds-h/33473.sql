WITH  CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
LineItemAggregates AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        COUNT(DISTINCT l.l_linenumber) AS LineCount,
        MAX(l.l_shipdate) AS LastShipDate
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    co.c_name,
    co.o_orderkey,
    co.o_orderdate,
    l.TotalRevenue,
    l.LineCount,
    l.LastShipDate,
    COALESCE(sp.TotalSupplyCost, 0) AS SupplierCost,
    CASE 
        WHEN l.TotalRevenue IS NULL THEN 'No Revenue'
        WHEN sp.TotalSupplyCost > 0 THEN 'High Supply Cost'
        ELSE 'Normal'
    END AS Status
FROM 
    CustomerOrders co
LEFT JOIN 
    LineItemAggregates l ON co.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierPerformance sp ON l.LineCount = sp.TotalSupplyCost
WHERE 
    co.OrderRank <= 5
ORDER BY 
    co.o_orderdate DESC, l.TotalRevenue DESC;
