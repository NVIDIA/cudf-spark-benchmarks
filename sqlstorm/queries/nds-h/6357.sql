WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_availqty,
        ps.ps_supplycost,
        (ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        (l.l_extendedprice * (1 - l.l_discount)) AS DiscountedPrice
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
),
AggregatedData AS (
    SELECT 
        np.n_name AS NationName,
        SUM(od.DiscountedPrice) AS TotalRevenue,
        COUNT(DISTINCT od.o_orderkey) AS NumberOfOrders,
        SUM(sp.TotalSupplyCost) AS TotalSupplyCost
    FROM 
        OrderDetails od
    JOIN 
        customer c ON od.o_orderkey = c.c_custkey
    JOIN 
        nation np ON c.c_nationkey = np.n_nationkey
    JOIN 
        SupplierParts sp ON od.l_partkey = sp.p_partkey
    GROUP BY 
        np.n_name
)
SELECT 
    NationName,
    TotalRevenue,
    NumberOfOrders,
    TotalSupplyCost,
    TotalRevenue / NULLIF(TotalSupplyCost, 0) AS RevenueToSupplyCostRatio
FROM 
    AggregatedData
ORDER BY 
    TotalRevenue DESC
LIMIT 10;