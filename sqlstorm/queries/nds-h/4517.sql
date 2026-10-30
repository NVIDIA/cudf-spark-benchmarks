WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
),
SupplierPartAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS TotalAvailable,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(wo.o_totalprice), 0) AS TotalSpent,
        COUNT(wo.o_orderkey) AS OrderCount
    FROM 
        customer c
    LEFT JOIN 
        RankedOrders wo ON c.c_custkey = wo.o_custkey AND wo.OrderRank <= 5
    GROUP BY 
        c.c_custkey, c.c_name
),
ProductDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        p.p_size,
        COALESCE(ps.TotalAvailable, 0) AS AvailableQty,
        COALESCE(ps.TotalSupplyCost, 0) AS SupplyCost
    FROM 
        part p
    LEFT JOIN 
        SupplierPartAvailability ps ON p.p_partkey = ps.ps_partkey
)
SELECT 
    c.c_name,
    SUM(co.TotalSpent) AS TotalCustomerSpend,
    COUNT(DISTINCT po.p_partkey) AS DistinctProductsPurchased,
    AVG(po.p_retailprice) AS AvgProductPrice,
    MAX(po.AvailableQty) AS MaxAvailableProductQty,
    (SELECT COUNT(DISTINCT l.l_orderkey) 
     FROM lineitem l 
     WHERE l.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '30 days'
     AND l.l_partkey IN (SELECT p.p_partkey FROM productdetails p)) AS RecentOrdersCount
FROM 
    customer c
JOIN 
    CustomerOrderSummary co ON c.c_custkey = co.c_custkey
LEFT JOIN 
    ProductDetails po ON c.c_custkey = po.p_partkey
WHERE 
    co.TotalSpent > 1000 AND po.AvailableQty IS NOT NULL
GROUP BY 
    c.c_name
ORDER BY 
    TotalCustomerSpend DESC
LIMIT 10;