WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS SupplierRank
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
TopRegions AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS SupplierCount
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_regionkey, r.r_name
    HAVING 
        COUNT(DISTINCT s.s_suppkey) > (SELECT AVG(SupplierCount) FROM (SELECT COUNT(DISTINCT s.s_suppkey) AS SupplierCount FROM nation n JOIN supplier s ON n.n_nationkey = s.s_nationkey GROUP BY n.n_nationkey) AS SubQuery)
),
FilteredLineItems AS (
    SELECT 
        l.*,
        CASE 
            WHEN l.l_discount > 0.05 THEN l.l_extendedprice * (1 - l.l_discount)
            ELSE l.l_extendedprice
        END AS NetPrice
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
        AND l.l_returnflag IS NULL
),
AggregatedData AS (
    SELECT 
        o.o_orderkey,
        SUM(f.NetPrice) AS TotalNetPrice,
        COUNT(DISTINCT f.l_orderkey) AS LineItemCount
    FROM 
        RankedOrders o
    JOIN 
        FilteredLineItems f ON o.o_orderkey = f.l_orderkey
    WHERE 
        o.OrderRank <= 10
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.r_name AS Region,
    SUM(ad.TotalNetPrice) AS OverallNetSales,
    AVG(ad.LineItemCount) AS AverageLineItems,
    CASE 
        WHEN SUM(ad.TotalNetPrice) > 10000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS RevenueCategory
FROM 
    AggregatedData ad
JOIN 
    TopRegions tr ON tr.SupplierCount > 5
JOIN 
    nation n ON n.n_nationkey = tr.n_regionkey
JOIN 
    region r ON tr.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name
ORDER BY 
    OverallNetSales DESC
LIMIT 5;