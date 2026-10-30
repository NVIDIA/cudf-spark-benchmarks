
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'F'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS PartCount
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
AggregateData AS (
    SELECT 
        r.r_name AS Region,
        COUNT(DISTINCT n.n_nationkey) AS NationCount,
        SUM(cd.OrderCount) AS TotalOrders,
        SUM(cd.TotalSpent) AS TotalRevenue
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        CustomerOrders cd ON c.c_custkey = cd.c_custkey
    GROUP BY 
        r.r_name
)
SELECT 
    rd.o_orderkey,
    rd.o_orderdate,
    rd.o_totalprice,
    sd.s_name AS SupplierName,
    ad.Region,
    ad.NationCount,
    ad.TotalOrders,
    ad.TotalRevenue
FROM 
    RankedOrders rd
JOIN 
    lineitem li ON rd.o_orderkey = li.l_orderkey
JOIN 
    partsupp ps ON li.l_partkey = ps.ps_partkey
JOIN 
    supplier sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    AggregateData ad ON 1=1 
WHERE 
    rd.OrderRank <= 10
ORDER BY 
    rd.o_totalprice DESC, ad.TotalRevenue DESC;
