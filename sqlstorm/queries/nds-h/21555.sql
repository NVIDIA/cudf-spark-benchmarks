WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '1995-01-01' AND '1996-12-31'
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalSpent,
        COUNT(o.o_orderkey) AS OrdersCount
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL OR COUNT(o.o_orderkey) = 0
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost ASC) AS PartRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
)
SELECT 
    n.n_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
    COUNT(DISTINCT o.o_orderkey) AS OrderCount,
    MAX(CASE 
        WHEN l.l_shipdate < l.l_commitdate THEN 'Early' 
        WHEN l.l_shipdate = l.l_commitdate THEN 'OnTime' 
        ELSE 'Late' 
    END) AS ShippingStatus,
    COALESCE(MAX(c.TotalSpent), 0) AS HighestCustomerSpending
FROM 
    lineitem l
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
INNER JOIN 
    TopCustomers c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_returnflag = 'N' AND
    (r.r_name IS NULL OR r.r_name LIKE 'A%')
GROUP BY 
    n.n_name
HAVING 
    AVG(l.l_extendedprice) > (SELECT AVG(l2.l_extendedprice) 
                               FROM lineitem l2 
                               WHERE l2.l_discount > 0.1)
UNION
SELECT 
    'Unknown' AS n_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
    COUNT(DISTINCT o.o_orderkey) AS OrderCount,
    'NotApplicable' AS ShippingStatus,
    NULL AS HighestCustomerSpending
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    l.l_shipmode NOT IN (SELECT DISTINCT l_shipmode FROM lineitem WHERE l_discount < 0.05)
    AND o.o_orderstatus IN ('O', 'F')
GROUP BY 
    o.o_orderstatus
HAVING 
    COUNT(DISTINCT o.o_orderkey) < 10;
